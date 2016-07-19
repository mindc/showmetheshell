function Shell(o) {
    var self = this;

    self.width = 132;
    self.height = 36;

    var container = $('#container');
    container.html('');

    self.close = function() {
    };

    self.init = function() {
        container.html('');

        self.shell = $('<div id="shell"></div>').appendTo( container );;
        self.shellCursor = $('<div id="shell-cursor" class="animated"></div>').appendTo( container );

        var spaces = '';
        for (var i = 1; i <= self.width; i++) {
            spaces = spaces + "&nbsp;";
        }

        for (var i = 1; i <= self.height; i++) {
            self.shell.append('<div class="row" id="row' + i + '">'+spaces+'</div>');
        }

        self.bind();
    };

    self.bind = function() {
        $(document).bind('keyup', function (e) {
            var code = e.keyCode || e.which;
            if (code == 27) {
                self.sendMessage({"type":"key","code":code});
            }
        });

        $(document).bind('keypress', function(e) {
			if ( e.keyCode ) {
				self.sendMessage({"type":"key","code":e.keyCode});
			} else if ( e.charCode ) {
				code = e.charCode;
				if ( e.ctrlKey ) {
					if ( code >= 97 ) {
						code -= 96
					}
				}
				self.sendMessage({"type":"char","code":code});
			}

            return false;
        });

    };

    self.sendMessage = function (message) {
        self.onsend( JSON.stringify( message ) );
    };

    self.updateRow = function(n, data) {
        var row = $('#row' + n);
        row.html(data);
    };

    self.moveCursor = function(x, y) {
		var w = self.shell.width()
		var h = self.shell.height()

		self.shellCursor.css({
			top: (h/self.height)*(y-1) + 'px',
			left: (w/self.width)*(x-1) + 'px'
		})
    };
}
