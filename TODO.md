- redis unreads
- everything (including singles) w/in the main pane refactor (options like 'commentable' and 'mark-as-unread-able')
- new comments ui
- other stuff

- better sharing from mobile

- two-paragraph comments collapse because of the first-of-type / last-of-type thing?

- maybe the same red in the comment stream as in the "(2 new)" message? Plus a little "New" thing? That fades when you click them? (Think about this again w/r/t redis refactor)

- clicking "my shared items" should automatically set the sort settings correctly
- if you click on someone's feed that has no new items, automatically go to 'all' and revchron

- "1 new items"

- every post should have a "single" page (but should be within pane)

- use redis for unreads instead of database

- clean up and improve and simplify code

- nicer style for blockquotes (maybe just italicize them? maybe not?)?

- refactor /entries
  - it'll render anything and paginate it
  - controller just gets a collection, doesn't care what of
  - "mark_as_read" and so on in the javascript work for entries, shares, comments, etc.

- don't allow unload if you've got a pending ajax request
  
- now that we're deleting old posts, allow starring. (and maybe starring should post to evernote if it's integrated?)

- use sendgrid webhooks to track opens/clicks as a way of marking things read. http://sendgrid.com/docs/API_Reference/Webhooks/event.html
- also if you go to a single post, mark as read

- graphs on "manage" page should be line charts plotting your comments + shares against the community's, and it should go back all time

- one-click evernote integration.

- style in bookmarklet should be clean and consistent on any website. expanding the note area should be easier. ideally we'd get the github box in the bookmarklet.

- prevent email duplicates and share/unshare/share rss problem with little delay (same with comments)

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
  - keep an eye on memory usage
  - why two index delayed jobs on adding a post?
  - upgrade to ubuntu 12.04 and oracle java 7.
- go back to sending share emails one at a time, share emails should use the magic links
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