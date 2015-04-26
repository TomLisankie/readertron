- old posts coming back (kat thing)?
- why isn't story order deterministic? (seeing unexpected results on mobile on reload)
- font size on mobile esp. gmail
- make it easier to share pdfs. it should "just work" from a URL ending in .pdf. embedly?
- bookmarklet should give spinner and remove "submit" button on click

- comment view the whole thing shouldn't be clickable
- follow an article without commenting on it

- speed, snappiness, loading errors on my index page

- clean up unreads of people who don't need them
- redis unreads?

- allow opening link in new tab on comment page

- blockquotes broken? http://www.readertron.com/reader/posts/460109#comment-4340 (gives arrow pointing wrong way, + no `<blockquote>` tag.)

- mobile bookmarklet?

- safari's tech for getting the full readable version of articles. make a separate service?

- why are http://www.readertron.com/reader/posts/445915#comment-4234 and http://www.readertron.com/reader/posts/445915 different? why are the links from the weekly digest not autologin?

- don't bold @mentions that don't refer to real people (this way we can also avoid the guards in the email code)

- if you type "@chip" and then hit space, it should auto-snap to "@Chip".

- @mentions should be able to have punctuation after them (and before them, a la open parens). right now it seems to add a space.
- and the mention subject line should (a) replace "@" with nothing (so that it reads more naturally) and (b) actually get the ellipses right.

- "do you have data for individuals? i bet i have some interesting gaps and then catch-up days"
- when does most readertron activity happen?

- everything (including singles) w/in the main pane refactor (options like 'commentable' and 'mark-as-unread-able')

- new comments ui

- loader in preview pane is being pushed down?

- why does $('#readertron-bookmarklet').atwho() not work on certain pages?

- a person's comments should appear in their named feed
- they should have unread status too
- the counts should all work out

- links to feeds and names in readertron should work

- redis queues can include every feed X configuration of sort settings

- two-paragraph comments collapse because of the first-of-type / last-of-type thing?

- maybe the same red in the comment stream as in the "(2 new)" message? Plus a little "New" thing? That fades when you click them? (Think about this again w/r/t redis refactor)

- clicking "my shared items" should automatically set the sort settings correctly
- if you click on someone's feed that has no new items, automatically go to 'all' and revchron

- "1 new items"

- every post should have a "single" page (but should be within pane)

- use redis for unreads instead of database

- nicer style for blockquotes (maybe just italicize them? maybe not?)?

- don't allow unload if you've got a pending ajax request
  
- now that we're deleting old posts, allow starring. (and maybe starring should post to evernote if it's integrated?)

- use sendgrid webhooks to track opens/clicks as a way of marking things read. http://sendgrid.com/docs/API_Reference/Webhooks/event.html
- also if you go to a single post, mark as read

- graphs on "manage" page should be line charts plotting your comments + shares against the community's, and it should go back all time

- one-click evernote integration.

- style in bookmarklet should be clean and consistent on any website. expanding the note area should be easier. ideally we'd get the github box in the bookmarklet.

- share later
  - or throttling
  - what would the second-order effects be?
- change subject line of comment emails to distinguish them more from shares
- scroll up on search results should move blue bar too
- more responsive "Quickpost" submit button.
- add Kraft, add Alkire
- ability to add a comment from within search results, without having to click the permalink
- scribd doc with secret_password param should automatically include it in embed url so that the embed works
- readertron weekly digest should be "from" "Readertron Weekly Digest" and the subject line should be comment content...
- collapsed view
- producer vs. consumpto (ratio of stories shared to read).
- "you haven't shared in a while"
- search
  - why two index delayed jobs on adding a post?
  - upgrade to ubuntu 12.04 and oracle java 7.
- change the copy in share emails to make the clickable area of "go to the post's page" slightly bigger
- single post should show within the regular pane.
- Reach out to non-participants.
- email links in regular share emails?
- fix annoying click scroll-to-top as on http://readertron.com/reader/posts/390710#comment-638
- apple-K for links.
- option persisted on users to sort things "newest first".
- printing a post
- better, simpler flow for adding new feeds.
- publish button
- keep an eye on feeds that haven't gotten a post in a while.
- is Feedzirra not getting new posts quickly enough?
- absolutizing relative URLs within posts, as in post 62 (in production).
- look at 404s to see which images are still broken?

- zen mode for long comments?

- Not sure how much harder this is, but can you have people's comments be unread items next to their name in "Other Shared Items"?

- people's gravatars, on sidebar and in notes