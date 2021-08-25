(function() {
    var change, changing, load_background, load_text, mode, modes, next_background_image_url;

    modes = ["kitten", "picsum", "lorempixel", "loremflickr", "dreamyimage"];

    mode = "kitten";

    changing = 0;

    next_background_image_url = function() {
        var grey, img, random_height, random_width, ratio, url;
        random_height = window.innerHeight || 600;
        random_width = window.innerWidth || 800;

        if (random_width > 800) {
            ratio = 800 / random_width;
            random_width = 800;
            random_height = Math.round(ratio * random_height);
        }
        if (random_height > 800) {
            ratio = 800 / random_height;
            random_height = 800;
            random_width = Math.round(ratio * random_width);
        }

        grey = "";
        if (Math.random() > 0.5) grey = "g";
        if (mode === "kitten") {
            url = "https://placekitten.com/" + grey + "/" + random_width + "/" + random_height;
        } else if (mode === "lorempixel") {
            url = "https://lorempixel.com/" + grey + "/" + random_width + "/" + random_height;
        } else if (mode === "picsum") {
            url = "https://picsum.photos/" + random_width + "/" + random_height;
        } else if (mode === "loremflickr") {
            url = "https://loremflickr.com/" + random_width + "/" + random_height;
        } else if (mode === "dreamyimage") {
            url = "https://more.iter.tw/image/*/" + random_width + "x" + random_height + ".jpg";
        }
        mode = modes[(1 + modes.indexOf(mode)) % modes.length];

        return url;
    };

    change = function() {
        if (changing === 3) {
            $("#screen").css("background-image", "url(" + $("#loader img").attr("src") + ")");
            $("#loader img").remove();
            $("#screen p").html($("#loader p").html());
            changing = 0;
        } else if (changing === 0) {
            changing = 1;
            load_text();
            load_background();
        }
        return setTimeout(change, 3000);
    };

    load_text = function() {
        return $("#loader p").moreText({
            'n': 1,
            'max': 45,
            'callback': function(sentences) {
                $(this).html(sentences.join("<br>"));
                return changing = changing + 1;
            }
        });
    };

    load_background = function() {
        var url = next_background_image_url() + "?random=" + Math.random();
        var img = new Image();

        var reload = setTimeout(function () {
            img.parentNode.removeChild(img);
            load_background();
        }, 9000);

        $(img).on("load", function() {
            clearTimeout(reload);
            return changing = changing + 1;
        });

        $("#loader").append(img);
        img.src = url;
    };

    jQuery(function() {
        jQuery.moreText.server = location.protocol + "//" + location.host;
        return change();
    });

}).call(this);
