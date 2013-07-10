$(document).ready(function() {
	$("#alert").fadeOut(3000);
	
	$.facebox.settings.closeImage = '/assets/closelabel.png'
	$.facebox.settings.loadingImage = '/assets/loading.gif'
	
	$('a[rel*=facebox]').live('click', function() {
		$.facebox({div: "#markdown-help"});
		return false;
	});
	
	$("#start-readertron").click(function() {
		window.location = "/";
	});
	
	$("#subscriptions li").live("click", function() {
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
	
	$("#subscriptions h3").live("click", function() {
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
		update_items_filter_control_counts();	
		fetch_entries();
	});
	
	if ($("#entries").length > 0) {
		$(document).scroll(function() {
			if (scrollFetchFlag && ($("#entries").height() - $(window).scrollTop() < 2700) && !$("#quickpost-form").length) {
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
	
	window.onbeforeunload = function (e) {
	  // For IE<8 and Firefox prior to version 4
	  if (e && ($("#quickpost-form").length || $("textarea[name='comment_content']:visible").length || $('.preview-content:visible').length)) {
	    e.returnValue = 'You still have unsaved changes!';
	  };

	  // For Chrome, Safari, IE8+ and Opera 12+
	  if ($("#quickpost-form").length || $("textarea[name='comment_content']:visible").length || $('.preview-content:visible').length) {
      alert("thing!!!")
	  	return 'You still have unsaved changes!';
    };
	  
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
  entries_request.abort();
  
	$("#entries").empty();
	$("#loading-area-container").show();
	entries_request = $.get("/reader/entries", SETTINGS, function(ret) {
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