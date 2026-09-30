# Concierge feedback over WhatsApp (PB-78).
#
# During the alpha, the MotifPath team is the student's teacher (the concierge). A student
# stuck on a lesson or an exercise sends a question or a recording through WhatsApp, and the
# team answers by hand. The platform only opens the conversation: it builds a prefilled
# https://wa.me link that tells the concierge who is writing and what they are looking at.
# No message, media or delivery status ever reaches motifpath-core.
#
# These scenarios are verified by motifpath-web's component tests and by manual browser
# checks, not by the core-domain BDD suite. Every value the message needs is already on the
# client: display_name (GET /users/me), the path title (GET /students/me/path), the lesson
# title (GET /content-nodes/{id}) and the ids.
#
# Concierge number: a build-time setting (VITE_CONCIERGE_WHATSAPP_NUMBER). It is not a secret,
# because the number is public by design.
#
# Reference format: <kind>-<first 8 hex characters of the id>, lowercase.
#   L-<node>              lesson screen: the content node
#   X-<node>/<exercise>   practice screen: the content node and the exercise on screen
# The concierge resolves a reference with an id prefix search (id::text LIKE '<hex>%').
# The prefix is not a hash, and it is not meant to be secret: the ids grant nothing without
# the student's session. It only keeps the message short and readable.
# Kind letters are never reused. "S" is reserved for practice sessions: once they ship, the
# practice screen's reference becomes S-<session>, and X- references that are already logged
# stay resolvable.
#
# Out of scope: sending media through the platform (graduates to ADR-021's presigned upload),
# the WhatsApp Cloud API, tracking the tap as a learning event, and routing the message to
# the authoring teacher's own business number (PB-82; the concierge number stays the fallback).

Feature: Send to your teacher
  As a student who is stuck on a lesson or an exercise
  I want to reach my teacher on WhatsApp in one tap, with the context already written
  So that I get feedback between lessons without explaining where I am

  Background:
    Given the concierge WhatsApp number is "+55 11 91234-5678"
    And the student "Ana Souza" follows the path "Blues Basics"
    And the path has the lesson "Shuffle in E" with content node id "3eb9ccc1-102f-81ee-8405-dc6fdbc5211b"
    And the lesson's practice shows the exercise with id "5c20a7e4-9b1d-4f0e-a3c2-7d8e9f001122" second

  # ── Where the button appears ─────────────────────────────────────────────────
  #
  # The button is a floating WhatsApp icon in the bottom-right corner of the screen, named
  # "Send to your teacher" for assistive technology. It carries no visible text of its own.

  Rule: The button appears on every unlocked lesson and on its practice

    Scenario: The lesson screen offers a floating WhatsApp button
      When the student opens the lesson "Shuffle in E"
      Then the student sees a floating WhatsApp icon named "Send to your teacher"
      And it stays in the bottom-right corner while the student scrolls

    Scenario: The practice screen offers the button while an exercise is shown
      When the student is on exercise 2 of the practice for "Shuffle in E"
      Then the student sees a floating WhatsApp icon named "Send to your teacher"

    Scenario: The button never covers the practice's Next control
      When the student is on exercise 2 of the practice for "Shuffle in E"
      Then the floating WhatsApp icon sits above the bar holding the "Next" control

    Scenario Outline: No button when there is no lesson to talk about
      When the lesson screen for "Shuffle in E" is in the "<state>" state
      Then no "Send to your teacher" button is shown

      Examples:
        | state     |
        | loading   |
        | locked    |
        | not-found |
        | error     |

  Rule: Without a configured number the feature is off

    Scenario: No number configured hides the button everywhere
      Given no concierge WhatsApp number is configured
      When the student opens the lesson "Shuffle in E"
      Then no "Send to your teacher" button is shown
      And the practice screen for "Shuffle in E" shows no "Send to your teacher" button either

  Rule: A tooltip explains the button on mouse hover or keyboard focus only

    Scenario: Hovering the button shows its tooltip
      When the student rests the mouse pointer on the floating WhatsApp icon
      Then a tooltip reads "Send to your teacher"
      And the tooltip adds "Opens WhatsApp. Your message goes to the MotifPath team."

    Scenario: Focusing the button from the keyboard shows the same tooltip
      When the student moves keyboard focus to the floating WhatsApp icon
      Then the tooltip reading "Send to your teacher" is shown

    Scenario: The tooltip is hidden otherwise
      When the student opens the lesson "Shuffle in E"
      And neither hovers nor focuses the floating WhatsApp icon
      Then no tooltip is shown

    # A touch screen has no hover: a tap opens WhatsApp straight away, and the WhatsApp icon
    # itself says where the tap leads. The tooltip's hint is not shown there.

  # ── What the button opens ────────────────────────────────────────────────────

  Rule: The button opens a wa.me link to the concierge number with a prefilled message

    Scenario: The link uses the number's digits only
      When the student taps "Send to your teacher" on the lesson "Shuffle in E"
      Then a new tab or the WhatsApp app opens "https://wa.me/5511912345678" with a "text" query parameter
      And the "text" parameter is the prefilled message, URL-encoded

    Scenario: The lesson message names the student, the path, the lesson and the lesson reference
      When the student taps "Send to your teacher" on the lesson "Shuffle in E"
      Then the prefilled message is:
        """
        Hi! I'm Ana Souza.
        Path: Blues Basics
        Lesson: Shuffle in E
        Ref: L-3eb9ccc1

        My question or recording:
        """

    Scenario: The practice message identifies the exercise on screen through its reference only
      When the student taps "Send to your teacher" on exercise 2 of the practice for "Shuffle in E"
      Then the prefilled message is:
        """
        Hi! I'm Ana Souza.
        Path: Blues Basics
        Lesson: Shuffle in E
        Ref: X-3eb9ccc1/5c20a7e4

        My question or recording:
        """

    Scenario: The reference follows the exercise the student is on
      Given the student is on exercise 2 of the practice for "Shuffle in E"
      When the student moves on to exercise 3, whose exercise id is "9f00aa11-0000-4000-8000-000000000003"
      And taps "Send to your teacher"
      Then the prefilled message's reference is "X-3eb9ccc1/9f00aa11"
      And the message states no exercise position or count

    Scenario: A student without a display name is not greeted by an empty name
      Given the student has no display name
      When the student taps "Send to your teacher" on the lesson "Shuffle in E"
      Then the prefilled message starts with "Hi!" on its own line
      And the message has no "I'm" sentence

  Rule: The message is written in the student's interface language

    Scenario: A Portuguese interface writes the message in Portuguese
      Given the student's interface language is "pt-BR"
      When the student taps "Send to your teacher" on the lesson "Shuffle in E"
      Then the floating WhatsApp icon is named "Enviar ao professor"
      And the prefilled message is:
        """
        Olá! Sou Ana Souza.
        Trilha: Blues Basics
        Lição: Shuffle in E
        Ref: L-3eb9ccc1

        Minha dúvida ou gravação:
        """
      And the reference is not translated
