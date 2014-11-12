# Keyano

A little app for playing the piano and identifying chords from your keyboard.


## Overview

Keyano is a side project that replicate the experience of playing the piano using a computer keyboard as the sole input modality. This document will describe the design decisions behind Keyano, as well as the basics of how the application works.


## The Idea

Fresh off of developing my first real side project in [Map XY](http://cmslewis.github.io/map-xy/), I was looking for a followup project that could help me continue my newfound frontend exercise regimen. I've been brainstorming on a few different ideas over the past few months, some of which I've mocked out in great detail, but I chose precisely none of them. Instead, I chose to make a piano.

A browser-based piano would present some interesting opportunities. First, it would finally allow me to explore the Web Audio API. I had previously read about the API's many capabilities in [Boris Smus's fantastic e-book](http://chimera.labs.oreilly.com/books/1234000001552/index.html), but I had never settled on a project that would let me put the API to good use. A piano would definitely do that, requiring not only the generation of sound but also the elegant stoppage of sound (if I were to implement a pedal, for instance). I was finally poised to enter the world of oscillator nodes, gain nodes, and audio contexts with a meaningful result in mind.

Another exciting opportunity with this project idea was the chance to make an online piano that was actually usable. Most online pianos I had used before were flash-based and clunky, and I had never seen one that was easily playable from a computer keyboard. Moreover, I had never seen a piano online or otherwise that could effectively identify chords as you played them. This could be a killer feature if done well.

The result of

## The Sound

The entire Keyano app began with a few simple lines that leveraged the Web Audio API's OscillatorNode. For instance, the following Javascript snippet will play A440 as a sine wave in the browser:

    var audioContext   = new (window.AudioContext || window.webkitAudioContext);
    var oscillatorNode = audioContext.createOscillator();
    
    oscillatorNode.frequency.value = 440;
    oscillatorNode.connect(audioContext.destination);
    
    oscillatorNode.start();

We can then stop the pitch with the following snippet:

    oscillatorNode.stop();

We can now easily trigger a particular pitch when a particular keyboard key is pressed:

    var audioContext = new (window.AudioContext || window.webkitAudioContext);
    var oscillatorNode;
    
    $(document).on('keydown', function(ev) {
      if (ev.keyCode === 32) { // The space bar
        oscillatorNode = audioContext.createOscillator();
        oscillatorNode.frequency.value = 440;
        oscillatorNode.connect(audioContext.destination);
        oscillatorNode.start();
      }
    });
    
    $(document).on('keyup', function(ev) {
      if (ev.keyCode === 32) { // The space bar
        oscillatorNode.stop();
      }
    });


This is exactly how piano pitch playback works in Keyano. Refer to [`KeyanoInstrument.coffee`](https://github.com/cmslewis/keyano/blob/master/static/js/instrument/KeyanoInstrument.coffee) to see the complete implementation.


## The HTML/CSS

Recent web design trends are favoring flatness and minimalism over photo-realism and skeumorphism. Nevertheless, Keyano opts for a decidedly photo-realistic look, both because it provided clearer affordances and because it made the CSS more interesting to write. (I'll admit it: I was crickety and in need of a good `box-shadow` kata). The stylesheets themselves are nicely modularized thanks to our good friends, the [LESS precompiler](http://lesscss.org/) and the [Suit.CSS](https://github.com/suitcss/suit/blob/master/doc/naming-conventions.md) style guidelines. Furthermore, the HTML scheme is concise and cleanly supports piano keyboards of arbitrary ranges. You can peruse [`KeyanoInstrument.less`](https://github.com/cmslewis/keyano/blob/master/static/js/instrument/KeyanoInstrument.coffee) and [`index.html`](https://github.com/cmslewis/keyano/blob/master/index.html) to see exactly how the piano's HTML and CSS are structured.


## The Chords

Once the piano was functional, the next feature idea to emerge was the ability to automatically recognize pitches, intervals, and even chords - all in real time. The KeyanoInstrument class did its part here by exposing a new method [getImpressedPianoKeys] that returned all currently active piano keys. The work of naming the combination of active keys is outsourced to the [`KeyanoKeyCombinationNameReporter`](https://github.com/cmslewis/keyano/blob/master/static/js/listeners/KeyanoKeyCombinationNameReporter.coffee) class, which simply invokes [getImpressedPianoKeys] on piano-press events, determines the name through a series of utility methods, then outputs the name to the DOM.

### Naming Pitches and Intervals

Naming pitches and intervals is trivial, as we can simply print the name of the pitch or the difference between two provided pitch indices on the piano, respectively. The algorithm for determing the name of an arbitrary key combination is much more interesting and worth describing in detail.

### Representing a Chord

Before we even think about a chord-naming algorithm, we need a representation--or "signature"--that can uniquely define a particular chord in a particular inversion. One approach is to simply encode the piano key IDs that consistute the chord. For instance, a C Major chord might be encoded as `'C-E-G'`. The problem with this approach is that it demands that we enumerate signatures for every possible chord in every possible key. Thus, whenever we add a new chord, we need to add it 12 times: once in each key.

A better option is to encode not the absolute pitches that comprise the chord, but rather the intervals *between* the pitches. In this scheme, a C Major chord, a Db Major chord, and indeed every other major chord will have the same signature of `'0-4-3'`. `0` indicates that the lowest note of the chord is in unison with itself, `4` indicates that the second note is 4 half-steps above the first note, and `3` indicates that the third note is 3 half-steps above the second note. This scheme produces a unique signature for each chord in each of its inversions, and it only requires us to add one entry when adding a new chord (not counting additional entries for its inversions).

Once we identify the signature of a particular key combination, we still need to determine which inversion the chord is in and what the chord is called. These properties are encoded explicitly for each chord in giant mapping from chord signature to chord data, in [`ChordData.coffee`](https://github.com/cmslewis/keyano/blob/master/static/js/data/ChordData.coffee). To save you a round trip to that file and back, the file looks like this:

    ChordData =
    
      # Major Triad
    
      '0-4-3' :
        name : 'Major'
        root : 0
      '0-3-5' :
        name : 'Major (First Inversion)'
        root : 2
      '0-5-4' :
        name : 'Major (Second Inversion)'
        root : 1
    
      ...

Note that the inversion varies with the 'root' property, which encodes which of the three pitches in the chord is the root (counting from the lowest pitch upward).

### Identifying a Chord

Identifying a chord is easy if the user plays one that is explicitly included in `ChordData`. The recognition algorithm simply needs to get the currently active piano keys, compute their chord signature by observing the difference in half-steps between each successive key, then print the concatenation of the root key name and the chord name for that signature.

Unfortunately, this approach breaks down entirely in two cases: (1) if the user plays an open chord whose signature does not appear in `ChordData`, (2) if the user plays a chord with duplicate pitches in different octaves. The brute-force way to handle this is to simply encode every possible open spelling of every chord up to some threshold of keyboard size - AND ALSO encode every spelling that includes duplicate pitches in higher octaves. A nightmare, to be sure. Fortunately, if we can come up with a general way to reduce a chord to its concise, closed form, then we'll be able to handle the two aforementioned cases without adding any additional entries.

The approach works as follows:

1. Get all currently active pitches.
2. Keep only the lowest instance of each pitch; disregard all higher instances.
3. For each note in the chord from highest to lowest pitch:
3.1 Drop the highest pitch to the lowest instance that is still above the base pitch in the chord.
3.2 If such an instance does not exist, we can stop, as we have an unrecognized chord.
3.3 Otherwise, recompute the signature of this new chord.
3.4 If that signature is appears in `ChordData`, we're done.

As this functionality does not depend on any external state, it has been pulled out into the `identifyPianoKeyCombination` function in [`pianoKeyUtils.coffee`](https://github.com/cmslewis/keyano/blob/master/static/js/utils/pianoKeyUtils.coffee).

