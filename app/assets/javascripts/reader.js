$(document).ready(function() {	
	$("#alert").fadeOut(3000);
	
	$("#start-readertron").click(function() {
		window.location = "/";
	});
	
	$("#subscriptions li").click(function() {
		SETTINGS.feed_id = $(this).split_id();
		SETTINGS.page = 0;
		update_items_filter_control_counts();
		fetch_entries();
		$("#subscriptions li, #subscriptions h3").removeClass("selected");
		$(this).addClass("selected");
		return false;
	});
	
	$(".meta-page input[type=text], .meta-page input[type=password], .meta-page input[type=email]").focus(function() {
		placeholderStack.push($(this).attr("placeholder"));
		$(this).attr("placeholder", "");
	});
	
	$(".meta-page input[type=text], .meta-page input[type=password], .meta-page input[type=email]").focusout(function() {
		$(this).attr("placeholder", placeholderStack.pop());
	})
	
	$("#subscriptions h3").click(function() {
		if ($(this).attr("id") == "my-shared-items") {
			window.location = "/reader/mine";
			return false;
		};
		if ($(this).attr("id") == "comment-stream") {
			window.location = "/reader/stream";
			return false;
		};
		SETTINGS.feed_id = $(this).attr("feed_id");
		update_items_filter_control_counts();
		$("#subscriptions li").removeClass("selected");
		$("#subscriptions h3").removeClass("selected");
		$(this).addClass("selected");
		SETTINGS.page = 0;
		fetch_entries();
		return false;
	});
	
	$("#all-items-link").closest("h3").addClass("selected");

	$("#subscriptions").slimScroll({
		height: $(window).height() + "px",
		wheelStep: 5,
		allowPageScroll: false
	});

	$(".item-body a:not(.cancel-edit-quickpost)").live("click", function() {
		window.open($(this).attr("href"), '_blank');
		return false;
	});
	
	$(".view-all-items").live("click", function() {
		SETTINGS.page = 0;
		SETTINGS.items_filter = "all";
		$("#unread-or-all .menu-button-caption").text("All items");
		fetch_entries();
	});
	
	if ($("#entries").length > 0) {
		$(document).scroll(function() {
			if (scrollFetchFlag && ($("#entries").height() - $(window).scrollTop() < 2700)) {
				SETTINGS.page = SETTINGS.page + 1;
				scrollFetchFlag = false;
				append_entries();
			};
		});
		update_items_filter_control_counts();	
	};
	
	$("#logo").click(function() {
		window.location = "/";
	});

	$(".entry.stream-comment").live("click", function() {
		window.location = $(this).find("a.entry-title-link").attr("href") + "#comment-" + $(this).attr("comment_id");
	});
	
	//  changes mouse cursor when highlighting lower right of box
    $(".comment-add-form textarea").live("mousemove", function(e) {
        var myPos = $(this).offset();
        myPos.bottom = $(this).offset().top + $(this).outerHeight();
        myPos.right = $(this).offset().left + $(this).outerWidth();

        if (myPos.bottom > e.pageY && e.pageY > myPos.bottom - 16 && myPos.right > e.pageX && e.pageX > myPos.right - 16) {
            $(this).css({ cursor: "se-resize" });
        }
        else {
            $(this).css({ cursor: "" });
        }
    })
    //  the following simple make the textbox "Auto-Expand" as it is typed in
    .live("keyup", function(e) {
        //  this if statement checks to see if backspace or delete was pressed, if so, it resets the height of the box so it can be resized properly
        if (e.which == 8 || e.which == 46) {
            $(this).height(parseFloat($(this).css("min-height")) != 0 ? parseFloat($(this).css("min-height")) : parseFloat($(this).css("font-size")));
        }
        //  the following will help the text expand as typing takes place
        while($(this).outerHeight() < this.scrollHeight + parseFloat($(this).css("borderTopWidth")) + parseFloat($(this).css("borderBottomWidth"))) {
            $(this).height($(this).height()+1);
        };
    });
	
	window.onbeforeunload = function (e) {
	  window.scrollTo(0, 0)
	};
});

var placeholderStack = [];

var scrollFetchFlag = true;

$.fn.split_id = function() {
	return this.attr("id").split("-")[1];
};

$.fn.snap_to_top = function() {
	$.scrollTo(this, {offset: -50});
};

$.fn.get_int = function() {
	return parseInt(this.text().replace(/[^0-9]/g, ""));
};

$.fn.replace_int = function(n) {
	this.text(this.text().replace(/[0-9]+/, n));
	return this;
};

$.fn.notch = function(n, simple) {
	if (typeof(simple) == "undefined") { simple = false };
	var new_n = this.get_int() + n;
	this.replace_int(new_n);
	if (simple) {
		return null;
	} else {
		(new_n == 0) ? this.hide().parent().removeClass("unread") : this.show().parent().addClass("unread");
		update_items_filter_control_counts();
	};
};

$.fn.zero = function() {
	this.notch_unreads(-1 * $("#feed-" + SETTINGS.feed_id + "-unread-count").get_int());
	this.hide().parent().removeClass("unread");
	update_items_filter_control_counts();
};

var next_post = function(offset) {
  if (($(".entry.current").attr("post_id") == $(".entry:first").attr("post_id") && offset == -1) || ($(".entry.current").attr("post_id") == $(".entry:last").attr("post_id") && offset == 1)) {
    return false;
  }
	if ($(".entry.current").length == 0) {
		var next = $(".entry:first");
	} else {
    if (offset == 1) {
      var next = $(".entry.current").next(".entry");
    } else if (offset == -1) {
      var next = $(".entry.current").prev(".entry");
    }
	};
  if (next)
		$(next).set_as_current_entry(true);
};

var fetch_entries = function() {
	$("#entries").empty();
	$("#loading-area-container").show();
	$.get("/reader/entries", SETTINGS, function(ret) {
		scrollFetchFlag = true;
		$("#entries").html(ret);
		$("#loading-area-container").hide();
		$.scrollTo($("#entries"), {offset: -50});
	});
};

var append_entries = function() {
	$("#entries").append($("#entries-loader").clone().show());
	$.get("/reader/entries", SETTINGS, function(ret) {
		if (ret.indexOf("no-entries-msg") != -1) {
			$("#entries #entries-loader").remove();
			$("#entries").append($("#end-of-the-line").clone().show());
			scrollFetchFlag = false;
		} else {
			$("#entries").append(ret);
			$("#entries #entries-loader").remove();
			scrollFetchFlag = true;			
		}
	});
};

var update_items_filter_control_counts = function() {
	var selector = "";
	if (SETTINGS.feed_id == "shared") {
		selector = "#shared-unread-count";
	} else if (SETTINGS.feed_id == "" || typeof(SETTINGS.feed_id) === "undefined") {
		selector = "#total-unread-count";
	} else {
		selector = "#feed-" + SETTINGS.feed_id + "-unread-count";
	};
	$(".items-filter-control-count").replace_int($(selector).get_int());
	$("#unread-or-all .menu-button-dropdown").css("left", ($("#unread-or-all .menu-button-caption").width() + 5) + "px")
};

var broadcast = function(msg) {
	$("#broadcast-message").text(msg).parent().show().fadeOut(3000);
};