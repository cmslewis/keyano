define [], ->


  ChordData =


    # Triads
    # ======

    # Triads (Root Position)

    '0-3-3' :
      quality : 'Diminished Triad'
      root    : 0
    '0-3-4' :
      quality : 'Minor Triad'
      root    : 0
    '0-4-3' :
      quality : 'Major Triad'
      root    : 0

    # Triads (Root Position) + Upper Octave

    '0-3-4-5' :
      quality : 'Minor Triad'
      root    : 0
    '0-4-3-5' :
      quality : 'Major Triad'
      root    : 0

    # Triads (First Inversion)

    '0-3-5' :
      quality : 'Major Triad (First Inversion)'
      root    : 2
    '0-4-5' :
      quality : 'Minor Triad (First Inversion)'
      root    : 2

    # Triads (First Inversion) + Upper Octave

    '0-3-5-4' :
      quality : 'Major Triad (First Inversion)'
      root    : 2
    '0-4-5-3' :
      quality : 'Minor Triad (First Inversion)'
      root    : 2

    # Triads (Second Inversion)

    '0-5-4' :
      quality : 'Major Triad (Second Inversion)'
      root    : 1
    '0-5-3' :
      quality : 'Minor Triad (Second Inversion)'
      root    : 1

    # Triads (Second Inversion) + Upper Octave

    '0-5-4-3' :
      quality : 'Major Triad (Second Inversion)'
      root    : 1
    '0-5-3-4' :
      quality : 'Minor Triad (Second Inversion)'
      root    : 1


    # Sevenths
    # ========

    # Sevenths (Root Position)

    '0-4-3-4' :
      quality : 'Major 7'
      root    : 0
    '0-4-3-3' :
      quality : 'Dominant 7'
      root    : 0
    '0-3-4-3' :
      quality : 'Minor 7'
      root    : 0
    '0-3-3-4' :
      quality : 'Half Diminished 7'
      root    : 0
    '0-3-3-3' :
      quality : 'Diminished 7'
      root    : 0

    # Sevenths (Root Position) + Upper Octave

    '0-4-3-4-1' :
      quality : 'Major 7'
      root    : 0
    '0-4-3-3-2' :
      quality : 'Dominant 7'
      root    : 0
    '0-3-4-3-2' :
      quality : 'Minor 7'
      root    : 0
    '0-3-3-4-2' :
      quality : 'Half Diminished 7'
      root    : 0
    '0-3-3-3-3' :
      quality : 'Diminished 7'
      root    : 0

    # Sevenths (First Inversion)

    '0-3-4-1' :
      quality : 'Major 7 (First Inversion)'
      root    : 3
    '0-3-3-2' :
      quality : 'Dominant 7 (First Inversion)'
      root    : 3
    '0-4-3-2' :
      quality : 'Minor 7 (First Inversion)'
      root    : 3
    '0-3-4-2' :
      quality : 'Half-Diminished 7 (First Inversion)'
      root    : 3

    # Sevenths (Second Inversion)

    '0-4-1-4' :
      quality : 'Major 7 (Second Inversion)'
      root    : 2
    '0-3-2-4' :
      quality : 'Dominant 7 (Second Inversion)'
      root    : 2
    '0-3-2-3' :
      quality : 'Minor 7 (Second Inversion)'
      root    : 2
    '0-4-2-3' :
      quality : 'Half-Diminished 7 (Second Inversion)'
      root    : 2

    # Sevenths (Third Inversion)

    '0-1-4-3' :
      quality : 'Major 7 (Third Inversion)'
      root    : 1
    '0-2-4-3' :
      quality : 'Dominant 7 (Third Inversion)'
      root    : 1
    '0-2-3-4' :
      quality : 'Minor 7 (Third Inversion)'
      root    : 1
    '0-2-3-3' :
      quality : 'Half-Diminished 7 (Third Inversion)'
      root    : 1


  return ChordData
