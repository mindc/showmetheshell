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
        self.shellCursor = $('<div id="shell-cursor" class="blink"></div>').appendTo( container );

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
        
			$("#shell-cursor").addClass("blink")        
            var code = e.keyCode || e.which;
            if (code == 27) {
                self.sendMessage({"type":"key","code":code});
            }
        });

        $(document).keydown(function (e) {
			DEBUG && console.log( "KEYDOWN => keyCode: " +  e.keyCode + ", charCode: " + e.charCode + ", which: " + e.which )        
            var code = (e.keyCode ? e.keyCode : e.which);
            switch ( code ) {
				case 8:
				case 9:
				case 13:
				case 33:
				case 34:
				case 35:
				case 36:
				case 37:
				case 38:
				case 39:
				case 40:
				case 45:
				case 46:
				
				case 112:
				case 113:
				case 114:
				case 115:
				case 116:
				case 117:
				case 118:
				case 119:
				case 120:
				case 121:
				case 122:
				case 123:
					self.sendMessage({"type":"key","code":code});
					return false;
				default:
            }
        })



        $(document).bind('keypress', function(e) {
			DEBUG && console.log( "KEYPRESS => keyCode: " +  e.keyCode + ", charCode: " + e.charCode + ", which: " + e.which )        
			$("#shell-cursor").removeClass("blink")
//			if ( e.keyCode ) {
	//			self.sendMessage({"type":"key","code":e.keyCode});
			//} else if ( e.charCode ) {
				code = e.charCode;

				if ( e.ctrlKey ) {
					if ( code >= 97 ) {
						code -= 96
					}
				}
				self.sendMessage({"type":"char","code":code});
		//	}

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
