- going from 0 to 1 unread should change style of subscription h3
- don't dynamically add parens when unread count is 0
- change star icon to shared? (and use the little pencil thing for the share with note.)
- refresh ALL posts on feed fetch
- fix "mine" and such
- sorting options: chron, revchron (but only dynamically, not stored/saved like google reader. maybe a two-state button)
- user names
- backbone-y unread counts

- mark all as unread (only ALL, not with these stupid ranges), both for individual feeds and for the whole thing.
- infinite scroll
- what to show at the end of the infinite scroll

- modeling, controllers, separation of concerns
- cron job in separate thread to poll for new rss data
- pretty up the bookmarklet, and add useful information like title, and some sense of the post preview.

- where that big subscribe button was, put a compose post button. highlight those posts in red or something. shows up in a person's share feed.
- one-click instapaper integration.
- e-mail notifications about comments on your shared items, or on items you've commented on.
- title unread count

deploy

- starring posts
- search
- comment creation via e-mail replies.
- de-duplicate shared posts and those posts in the regular feed.
- one-click evernote integration.
- admin interface.
- "n <note>" integration via the api.
- print individual post.
- gamifying:
	- surfacing long comments
	- ability to rank comments? (+1 for "best of")
	- most shared
	- most shared from feed
	- be especially fond of finds that come in via the bookmarklet
	- producer vs. consumpto (ratio of stories shared to read)
	- encourage original posts
	- send e-mail to people with summary of what they've been missing, new content, etc.