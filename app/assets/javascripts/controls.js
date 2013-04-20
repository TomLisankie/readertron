$(document).ready(function() {
	$("#viewer-refresh").mouseover(function() {
		$(this).removeClass("jfk-button-standard").addClass("jfk-button-hover");
	});

	$("#viewer-refresh").mouseout(function() {
		$(this).removeClass("jfk-button-hover").addClass("jfk-button-standard");
	});

	$("#viewer-refresh").click(function() {
		SETTINGS.page = 0;
		fetch_entries();
		return false;
	});
	
	$("#unread-or-all").mouseover(function() {
		$(this).removeClass("jfk-button-standard").addClass("jfk-button-hover");
	});

	$("#unread-or-all").mouseout(function() {
		$(this).removeClass("jfk-button-hover").addClass("jfk-button-standard");
	});
	
	$("#unread-or-all").click(function(event) {
		$("#unread-or-all-menu").show();
		$(document).one("click", function() {
			$("#unread-or-all-menu").hide();
		});
		event.stopPropagation();
	});
	
	$('#feed-all-items-filter').click(function() {
		SETTINGS.page = 0;
		SETTINGS.items_filter = "all";
		SETTINGS.date_sort = "revchron";
		$("#chron").removeClass("jfk-button-checked").addClass("jfk-button-unchecked");
		$("#revchron").removeClass("jfk-button-unchecked").addClass("jfk-button-checked");
		$("#unread-or-all .menu-button-caption").text("All items");
		update_items_filter_control_counts();
		fetch_entries();
	});
	
	$("#feed-unread-items-filter").click(function() {
		SETTINGS.items_filter = "unread";
		SETTINGS.page = 0;
		SETTINGS.date_sort = "chron";
		$("#revchron").removeClass("jfk-button-checked").addClass("jfk-button-unchecked");
		$("#chron").removeClass("jfk-button-unchecked").addClass("jfk-button-checked");
		$("#unread-or-all .menu-button-caption").html("<span id='new-items-count-visible'>" + $("#new-items-count-hidden").text() + "</span> new items")
		update_items_filter_control_counts();
		fetch_entries();
	});
	
	$("#revchron").mouseover(function() {
		$(this).removeClass("jfk-button-unchecked").addClass("jfk-button-hover");
	});

	$("#revchron").mouseout(function() {
		$(this).addClass("jfk-button-standard");
	});
	
	$("#revchron").click(function() {
		$("#chron").removeClass("jfk-button-checked").addClass("jfk-button-unchecked");
		$(this).removeClass("jfk-button-unchecked").addClass("jfk-button-checked");
		SETTINGS.page = 0;
		SETTINGS.date_sort = "revchron";
		fetch_entries();
	});
	
	$("#chron").mouseover(function() {
		$(this).removeClass("jfk-button-unchecked").addClass("jfk-button-hover");
	});

	$("#chron").mouseout(function() {
		$(this).addClass("jfk-button-standard");
	});
	
	$("#chron").click(function() {
		$("#revchron").removeClass("jfk-button-checked").addClass("jfk-button-unchecked");
		$(this).removeClass("jfk-button-unchecked").addClass("jfk-button-checked");
		SETTINGS.page = 0;
		SETTINGS.date_sort = "chron";
		fetch_entries();
	});
	
	$("#mark-all-as-read").mouseover(function() {
		$(this).removeClass("jfk-button-standard").addClass("jfk-button-hover");
	});

	$("#mark-all-as-read").mouseout(function() {
		$(this).removeClass("jfk-button-hover").addClass("jfk-button-standard");
	});

	$("#mark-all-as-read").click(function() {
		$(".entry:first").zero();
		
		$.post("/reader/mark_all_as_read", {feed_id: SETTINGS.feed_id}, function(ret) {
			SETTINGS.page = 0;
			fetch_entries();
			broadcast("Marked all entries as read.")
		});
		return false;
	});
	
	$("#quickpost-button").mouseover(function() {
		$(this).addClass("hover");
	});
	
	$("#quickpost-form textarea").live('focus', function() {
		$(this).closest(".write-content").addClass("focused");
	});
	
	$("#quickpost-form textarea").live('blur', function() {
		$(this).closest(".write-content").removeClass("focused");
	});
	
	$("#quickpost-form .preview-tab").live('click', function() {
		$(this).closest(".previewable-comment-form").removeClass("write-selected").addClass("preview-selected");
		$(this).addClass("selected")
		$(this).closest(".tabnav-tabs").find(".write-tab").removeClass("selected");
		
		$(this).closest(".discussion-bubble-inner").find(".comment-body").html($("#entries-loader").clone().show());
		$(this).closest(".discussion-bubble-inner").find(".comment-body").load("/reader/markdownify", 
			{content: $(this).closest(".discussion-bubble-inner").find("textarea").val()}
		);
		return false;
	});
	
	$("#quickpost-form .write-tab").live('click', function() {
		$(this).closest(".previewable-comment-form").removeClass("preview-selected").addClass("write-selected");
		$(this).addClass("selected")
		$(this).closest(".tabnav-tabs").find(".preview-tab").removeClass("selected");
		return false;
	});
	
	$("#quickpost-button").mouseout(function() {
		$(this).removeClass("hover");
	});
	
	$("#quickpost-button").live("click", function() {
		scrollFetchFlag = false;
		$("#entries").html($("#quickpost-form-template").clone().attr("id", "quickpost-form").show());
		$("#quickpost-form input#title").focus();
	});
	
	$("#cancel-quickpost").live("click", function() {
		fetch_entries();
		return false;
	});
	
	$("#quickpost-form button[type=submit]").live("click", function() {
		$.post("/reader/quickpost", {title: $(this).closest("#quickpost-form").find("input[name=title]").val(), content: $(this).closest("#quickpost-form").find("textarea").val()}, function(ret) {
			fetch_entries();
			broadcast("Your post has been created and shared successfully!");
		});
		return false;
	});
	
	$("#settings-button").mouseover(function() {
		$(this).removeClass("jfk-button-standard").addClass("jfk-button-hover");
	});

	$("#settings-button").mouseout(function() {
		$(this).removeClass("jfk-button-hover").addClass("jfk-button-standard");
	});
	
	$("#settings-button").click(function(event) {
		$("#settings-menu").show();
		$(document).one("click", function() {
			$("#settings-menu").hide();
		});
		event.stopPropagation();
	});
	
	$("#subscriptions-management-link").click(function() {
		window.location = "/subscriptions";
	});
	
	$("#user-settings-link").click(function() {
		window.location = "/users/edit";
	});
	
});