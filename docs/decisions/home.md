# Home

Records for the Home tab. See [README.md](README.md) for why these live here
rather than in the source.

## Home stopped being a gallery

Home was a full-bleed grid of every screenshot. That made SHOTO look like a
copy of the system photo app: opening it answered *"what do I have?"* — a
question the gallery already answers — instead of *"what should I do?"*.

The grid moved to its own Library tab, which is what let Home become a hub.
Browsing is still one tap away; it just no longer *is* the app.

**Still true in the source:** Home surfaces the unsorted count and the work
the app can do on the user's behalf. Library owns the grid.

## The hero has had three shapes

It began as a slab of accent colour with a glow under it. It became a bordered
surface with a coloured rule. It is now nothing at all — a figure, a line of
text, and the page behind it.

Each step removed a container and the screen got better, which is the whole
argument: what made Home read as generated was that every piece of information
on it had been put in a box, and seven boxes stacked vertically is the shape of
a template regardless of what is written in them.

A 58px numeral in the display face outranks anything a border can do. It needs
no fill to be the first thing you see, it costs one text node instead of a
decorated container, and it lets the count be *read* rather than presented.

**Do not** put the hero back in a card.

## Search moved out of the corner, then learned to wait

Search was a 44px circle in the top-right — the least reachable point on a tall
phone held in one hand, for the single most valuable action in an app whose
purpose is finding a screenshot again. It was *also* duplicated as a row at the
bottom of the tools list, so the app had two entry points to its best feature
and both were awkward.

It became a full-width field, second on the page. That is reachable,
unmistakable, and does a second job for free: the placeholder says the app
searches *what a picture shows*, which nobody guesses a screenshot app can do.

Later it learned to disappear. On a fresh install the field sat directly above
the words "Nothing saved", inviting a search of a library of zero — and until
the paywall moved, tapping it asked for money. A control that cannot succeed is
worse than no control.

**Still true in the source:** the field appears only when the library is
non-empty, and search has exactly one entry point per screen.

## The tools section has been renamed twice

It was "What SHOTO can do" — a brochure heading, describing the software to
you. That became "Do something", which fixed the brochure problem and
introduced a vaguer one: it is an instruction, and a faintly condescending one
to give somebody who has just opened an empty app.

It is now two headings, because the list answers two different questions.
With nothing saved it is the only thing on screen worth touching, so it says
where to begin. With a library it is a toolbox, and the plainest available noun
beats any instruction.

## The tool rows stopped being sign-posts

Safe share and Merge used to answer a tap with a snackbar: *"Open a screenshot,
then tap Safe share."* / *"Long-press two or more screenshots in your library,
then tap Merge."* Three instructions, one of them a gesture with no visual
affordance, on a screen the user had to find first.

A row that looks like a button and behaves like a sign-post was the single
least professional thing this screen did. They now open the Library already in
selection mode, asking for what they need — the app performs the step it used
to narrate.

On an empty library there is nothing to select, so they open the picker
instead. Find duplicates was the worst case: it went straight to the paywall,
so the app's answer to *"what does this do?"* was to ask for money to scan
nothing.

## The counts were three cards, then one card, then a sentence

Three bordered stat cards became one card with three columns and are now a
single line of text. Each step asked whether the container was earning its
place; none of them was.

They are hidden entirely while the library is empty. "Screenshots 0 ·
Favorites 0 · Folders 0" restated the headline's claim three more times, in the
space between the one action on the screen and the way to reach it.
