# Curriculum principles

The premises that shape the knowledge map (`catalogs/knowledge-map.yaml`) and the default
courses and paths built on it. They follow from the practice model (ADR-046), the
practice-first experience language (ADR-049), the knowledge graph (ADR-043), and the course
and path catalogs (ADR-029, ADR-042), plus desk research on what learners look for.

**Status:** Draft, 2026-10-09. Premises marked *hypothesis* come from desk research, not
from measured data. Each one names the MotifPath events that will confirm or refute it.

## A. Who learns, and what keeps them

1. **Learners come to play songs, not to learn music theory.**
   - Evidence: chord searches for whole songs lead search demand. "Hallelujah" alone gets
     about 163k searches a month worldwide, and "Wish You Were Here" leads in Brazil.
     Finishing a whole song is the point where a beginner commits (Fender). About 90% of new
     players quit within a year (Fender).
   - **Map:** the repertoire skills (`learn-song-by-sections`, `play-along-recording`,
     `perform-song`) are the destination every branch serves, not a side root.
2. **The first win happens in the first session.**
   - Evidence: the most-viewed lessons are "your very first lesson" and "your first song in
     10 minutes" (Marty Music, JustinGuitar, the leading Brazilian channels).
   - **Map:** each instrument has a complete beginner chain, every link at level B, that ends
     in a song: hold → tune → two chords → steady strum or groove → song.
3. **Brazil first, in repertoire as well as language.** *Hypothesis.*
   - Evidence: Cifra Club's most-accessed songs are mostly gospel/worship and sertanejo, with
     Brazilian rock next. MPB and bossa follow.
   - **Map:** style stays a tag on content, never a branch of the tree. But the skills those
     styles need exist at beginner level: simple strumming recipes, accompanying a singer,
     playing in a worship or church band.
   - Confirm with: course and path enrolment by style tag, and play-along completion.
4. **The early quitting points are physical and predictable:** tuning, finger pain, posture,
   barre chords and the F chord.
   - **Map:** each has a skill that practice and recommendations can target. Today
     `play-e-shape-barre` covers barre chords, but nothing covers building finger strength
     and calluses, or posture without pain.
   - Confirm with: early-left and abandoned sessions in the first four weeks, by skill
     (ADR-046 events).

## B. What the map models

5. **A skill is something a learner can practise and the platform can get evidence on.**
   - **Map:** every leaf skill names at least one practice item kind (ADR-046) that can
     measure it. Habits such as planning practice or practising slowly can't be graded yet.
     They stay skills, so they keep their place on the learner's map, and the practice
     session carries them (the tempo ladder, the session composer) until an item kind can
     measure them. Turning them into concepts would hide them, since concepts get no
     progress line (ADR-046).
6. **Concepts exist to be applied.**
   - **Map:** every non-placeholder concept is applied by at least one skill, on every
     instrument the concept is for.
7. **Theory enters through use.** *Hypothesis.*
   - Evidence: Brazilian learners look for campo harmônico (diatonic chords) as "play any
     song in any key" or "work songs out by ear".
   - **Map:** `diatonic-chords` and `transposition` move towards early intermediate, reached
     through skills like `play-shapes-in-any-key`, `find-key-by-ear` and
     `choose-capo-for-singer`, not through a chain of theory.
   - Confirm with: readiness and evidence on those skills against their stated levels.
8. **Level belongs to an instrument, not to a node** (ADR-043).
   - **Map:** keep the per-instrument level calibration, and use it to check premise 2 for
     every instrument.

## C. How the map serves practice

9. **`requires` orders and measures readiness; it never locks anything** (ADR-043).
   - **Map:** no `requires` edge targets a node with no leaf skill on an instrument where the
     edge counts. Where guitar edges don't count on bass, bass has its own prerequisites.
10. **Short phone sessions, often with the instrument in hand** (ADR-049).
    - **Map:** skills are narrow enough that a 5–10-minute session moves one forward. A
      skill that takes a whole course to show progress is split.
11. **Fluency and retention come from coming back to a skill**, not from finishing a lesson.
    - **Map:** `fluent` and `retained` requirements say how far apart two skills sit in a
      sequence, and are the main input for spiral review.

## D. How paths and courses use the map

12. **A path promises something playable** (a song, a groove, a solo), not a topic. It is
    anchored on one main skill and 2–5 supporting skills, and ends with an application
    play-along.
13. **A path's skills feed the learner's practice pool** (ADR-046's session composer). The
    number of new skills a pool can absorb without diluting sessions limits path size.
14. **Courses are spirals, not syllabi.** Later paths bring earlier skills back as warm-ups
    and review.
15. **Every path also works on its own** (ADR-042). It states the skills it assumes at
    `accurate`, and the session composer may bring in a missing one as a stretch item.

## Open questions

- Does a path's practice pool come only from its lessons' skill tags, or does a path list
  practice items explicitly, such as the play-along that closes it?
- How many new skills can one path add to a learner's pool?
- Does a course's checkpoint order also feed the composer's priority, or only the order
  lessons unlock in?

## Sources

- Fender's study on first-year quitting, as reported by
  [MusicRadar](https://www.musicradar.com/news/90-of-beginner-guitar-players-give-up-within-a-year-says-fender)
  and [Guitar World](https://www.guitarworld.com/news/90-percent-of-new-guitarists-abandon-the-instrument-within-a-year-according-to-fender).
- Song-chord search volumes, from
  [guitar.com](https://guitar.com/news/music-news/leonard-cohen-hallelujah-most-googled-song-guitar/)
  and [Wood and Fire Studio](https://woodandfirestudio.com/en/most-played-songs-and-riffs/).
- Fender Play's most-learned song,
  [guitar.com](https://guitar.com/news/industry-news/andy-mooney-most-popular-song-fender-play-oasis-wonderwall/).
- Most-viewed first lessons: [Marty Music](https://youtube.fandom.com/wiki/Marty_Music),
  [JustinGuitar stats](https://vidiq.com/youtube-stats/channel/UCBNkm8o5LiEVLxO8w0p2sfQ/).
- [Cifra Club most-accessed songs](https://www.cifraclub.com.br/mais-acessadas/).
- Brazilian beginner difficulties,
  [Terra](https://www.terra.com.br/diversao/musica/violao-para-iniciantes-3-grandes-desafios-que-voce-precisa-vencer,6a736808538c39d737a3a94e93a004aafcxlzzok.html)
  and [Cifra Club blog](https://www.cifraclub.com.br/blog/violao-para-iniciantes-erros/).
