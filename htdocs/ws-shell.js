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
		$(document).bind({
			keydown: function( e ) {
				if ( e.keyCode == 16 || e.keyCode == 17 || e.keyCode == 18 ) return
				var code = e.key.charCodeAt()
				if ( e.key.length > 1 ) {
					self.sendMessage({"type":"key","code":e.keyCode});			
				} else {
					if ( e.ctrlKey && code > 96 && code <= 127)
						code -= 96			
						
					if ( code > 127 ) {
						self.sendMessage({"type":"key","code":code});					
					} else {	
						self.sendMessage({"type":"char","code":code});
					}
					
					
				}
				return false
			}
			
		})
    };

    self.sendMessage = function (message) {
		DEBUG && $('#debug').prepend('<div style="background-color:lightyellow">[SEND] '+JSON.stringify( message )+'</div>')
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
