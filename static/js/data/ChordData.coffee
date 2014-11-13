define [], ->

  #
  # ChordData
  # =========
  # This is a giant object mapping closed chord signatures ('0-x-y...') to chord data. A chord signature is a string
  # encoding of a particular ordered key combination. As a convention, the first number should always be 0 (indicating
  # that the lowest key is effectively in unison with itself), while each successive number should indicate how many
  # half-steps there are between that key and the one immediately previous.
  #
  # For example: The encoding for a C Major triad (consisting of C, E, and G) would be '0-4-3'; because E is 4
  # half-steps above C, and G is 3 half-steps above E.
  #
  # Each chord's data should contain the name of the chord, and which key in the ordering is the root.
  #
  # For example: a major triad in first inversion might reasonably be named 'Major Triad (First Inversion)'. In the
  # case of a C Major Triad in first inversion (consisting of E, G, and the high C), the C is the root and is at index
  # 2 in the key ordering. Thus, we note that 'root' should in fact be 2 for major triads in first inversion.
  #

  ChordData =


    # Triads
    # ======

    # Diminished Triad

    '0-3-3' :
      name : 'Diminished Triad'
      root : 0
    '0-3-6' :
      name : 'Diminished Triad (First Inversion)'
      root : 2
    '0-6-3' :
      name : 'Diminished Triad (Second Inversion)'
      root : 1

    # Augmented Triad

    '0-4-4' :
      name : 'Augmented Triad'
      root : 0

    # Minor Triad

    '0-3-4' :
      name : 'Minor'
      root : 0
    '0-4-5' :
      name : 'Minor (First Inversion)'
      root : 2
    '0-5-3' :
      name : 'Minor (Second Inversion)'
      root : 1

    # Major

    '0-4-3' :
      name : 'Major'
      root : 0
    '0-3-5' :
      name : 'Major (First Inversion)'
      root : 2
    '0-5-4' :
      name : 'Major (Second Inversion)'
      root : 1


    # Sevenths
    # ========

    # Major 7

    '0-4-3-4' :
      name : 'Major 7'
      root : 0
    '0-3-4-1' :
      name : 'Major 7 (First Inversion)'
      root : 3
    '0-4-1-4' :
      name : 'Major 7 (Second Inversion)'
      root : 2
    '0-1-4-3' :
      name : 'Major 7 (Third Inversion)'
      root : 1

    # Dominant 7

    '0-4-3-3' :
      name : 'Dominant 7'
      root : 0
    '0-3-3-2' :
      name : 'Dominant 7 (First Inversion)'
      root : 3
    '0-3-2-4' :
      name : 'Dominant 7 (Second Inversion)'
      root : 2
    '0-2-4-3' :
      name : 'Dominant 7 (Third Inversion)'
      root : 1

    # Minor 7

    '0-3-4-3' :
      name : 'Minor 7'
      root : 0
    '0-4-3-2' :
      name : 'Minor 7 (First Inversion)'
      root : 3
    '0-3-2-3' :
      name : 'Minor 7 (Second Inversion)'
      root : 2
    '0-2-3-4' :
      name : 'Minor 7 (Third Inversion)'
      root : 1

    # Half Diminished 7

    '0-3-3-4' :
      name : 'Half Diminished 7'
      root : 0
    '0-3-4-2' :
      name : 'Half-Diminished 7 (First Inversion)'
      root : 3
    '0-4-2-3' :
      name : 'Half-Diminished 7 (Second Inversion)'
      root : 2
    '0-2-3-3' :
      name : 'Half-Diminished 7 (Third Inversion)'
      root : 1

    # Diminished 7

    '0-3-3-3' :
      name : 'Diminished 7'
      root : 0

    # Minor-Major 7

    '0-3-4-4' :
      name : 'Minor-Major 7'
      root : 0
    '0-4-4-1' :
      name : 'Minor-Major 7 (First Inversion)'
      root : 3
    '0-4-1-3' :
      name : 'Minor-Major 7 (Second Inversion)'
      root : 2
    '0-1-3-4' :
      name : 'Minor-Major 7 (Third Inversion)'
      root : 1

    # Augmented Major 7

    '0-4-4-3' :
      name : 'Augmented Major 7'
      root : 0
    '0-4-3-1' :
      name : 'Augmented Major 7 (First Inversion)'
      root : 3
    '0-3-1-4' :
      name : 'Augmented Major 7 (Second Inversion)'
      root : 2
    '0-1-4-4' :
      name : 'Augmented Major 7 (Third Inversion)'
      root : 1

    # Augmented 7

    '0-4-4-2' :
      name : 'Augmented 7'
      root : 0
    '0-4-2-2' :
      name : 'Augmented 7 (First Inversion)'
      root : 3
    '0-2-2-4' :
      name : 'Augmented 7 (Second Inversion)'
      root : 2
    '0-2-4-4' :
      name : 'Augmented 7 (Third Inversion)'
      root : 1


    # Suspensions
    # ===========

    # sus2

    '0-2-5' :
      name : 'sus2'
      root : 0
    '0-7-7-2' :
      name : 'sus2'
      root : 0

    # Minor sus2

    '0-7-7-1' :
      name : 'Minor sus2'
      root : 0

    # sus4

    '0-5-2' :
      name : 'sus4'
      root : 0
    '0-5-2-5' :
      name : 'sus4'
      root : 0


    # Ninths
    # ======

    # Add 2 (Add 9)

    '0-2-2-3' :
      name : 'add2'
      root : 0
    '0-2-3-5' :
      name : 'add2 (Ninth as Root)'
      root : 3
    '0-3-5-2' :
      name : 'add2 (First Inversion)'
      root : 2
    '0-5-2-2' :
      name : 'add2 (Second Inversion)'
      root : 1

    # Major Ninths

    '0-4-3-4-3' :
      name : 'Major 9th'
      root : 0

    '0-7-4-3' :
      name : 'Major 9th (Missing 3rd)'
      root : 0

    '0-4-7-3' :
      name : 'Major 9th (Missing 5th)'
      root : 0

    # Dominant Ninths

    '0-4-3-3-4' :
      name : 'Dominant 9th'
      root : 0

    '0-7-3-4' :
      name : 'Dominant 9th (Missing 3rd)'
      root : 0

    '0-4-6-4' :
      name : 'Dominant 9th (Missing 5th)'
      root : 0


    # Dominant Minor Ninths

    '0-4-3-3-3' :
      name : 'Dominant Minor 9th'
      root : 0

    '0-7-3-3' :
      name : 'Dominant Minor 9th (Missing 3rd)'
      root : 0

    '0-4-6-3' :
      name : 'Dominant Minor 9th (Missing 5th)'
      root : 0

    # Minor Ninths

    '0-3-4-3-3' :
      name : 'Minor 9th'
      root : 0

    '0-3-7-3' :
      name : 'Minor 9th (Missing 5th)'
      root : 0

    # Dominant 7 Sharp 9th

    '0-4-3-3-5' :
      name : 'Dominant 7 Sharp 9th'
      root : 0


  return ChordData
