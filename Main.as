package {
	import flash.display.MovieClip;
	import flash.display.Graphics;
	import fl.motion.easing.Back;
	import flash.geom.Point;
	import flash.display.BitmapData;
	import flash.display.Bitmap;
	import flash.geom.Rectangle;
	import flash.events.*;
	import flash.net.*;
	import flash.ui.*;

	public class Main extends MovieClip {
		
		var mapW: int = 1000;
		var mapH: int = 1000;
		var numParticles: int = 300;
		var heroInfluence: Number = 100;
		var blockSize: int = stage.stageWidth / 10;
		var runSpeed: Number = 6;
		var manRad: Number = 15;
		var dir: String = "S";
		var prevState: String = null;



		
		var Model: Object = {};

		var numRows: int = mapH / blockSize;
		var numCols: int = mapW / blockSize;

		var map: Object = {};
		var cam: Object = {
			currRot_deg: 0
		};
		var speed: Number = 0;

		var g: Graphics = this.graphics;
		var arr: Array = [];
		var hero: Object;
		var jsonObj: Object;
		var src: BitmapData = new Man();
		var bd: BitmapData = new BitmapData(stage.stageWidth, stage.stageHeight, false, 0xffffff);
		var bmp: Bitmap = new Bitmap(bd);

		public function Main() {
			// constructor code
			stage.addChild(bmp);
			var _jsonLoader: URLLoader = new URLLoader();
			_jsonLoader.load(new URLRequest("man.json"));
			_jsonLoader.addEventListener(Event.COMPLETE, processJson);
		}


		function processJson(e: Event): void {
			var stringJson: String;

			stringJson = String(e.target.data);
			jsonObj = JSON.parse(stringJson);
			begin();
		}


		function begin(): void {
			for (var i: int = 0; i < numParticles; i++) {

				var found: Boolean = false;
				var rndX: Number = Math.random() * mapW;
				var rndY: Number = Math.random() * mapH;

				while (!found) {
					for (var j: int = 0; j < arr.length; j++) {
						var o: Object = arr[j];
						var minDist: Number = manRad * 2;
						if (getDistance(rndX, rndY, o.x, o.y) < minDist) {
							rndX = Math.random() * mapW;
							rndY = Math.random() * mapH;
							found = false;
							j = 0;
						}
					}
					found = true;
				}



				var circle: Object = {
					x: rndX,
					y: rndY,
					size: manRad,
					//pawn: new Pawn(),

					color: Math.random() * 0xffffff
				};


				if (i == int(numParticles / 2)) {
					circle.x = mapW / 2;
					circle.y = mapH / 2;
					circle.size = heroInfluence;
					circle.color = 0x00ffcc;

					hero = circle;
				}

				//circle.pawn.scaleX = circle.pawn.scaleY = 0.5;
				//addChild(circle.pawn);
				//setAnimFrame("IDLE_S", circle);
				//circle.pawn.gotoAndStop("IDLE_S")
				arr.push(circle);
			}

			arr.sortOn("y", Array.NUMERIC);
			stage.addEventListener(Event.ENTER_FRAME, update);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, myKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, myKeyUp);

		}

		function getZeros(num: int): String {
			var len: int = String(num).length;
			var str: String = "";
			for (var i: int = 0; i < 4 - len; i++) {
				str += "0";
			}

			str += num;
			return str;
		}


		function setAnimFrame(_name: String, o: Object): void {
			var frames: Object = jsonObj.frames;
			if (o.prevState != _name) {
				o.counter = 0;
			} else {
				o.counter++;
			}
			var frameObj: Object = frames[_name + getZeros(o.counter)];
			if (!frameObj) {
				o.counter = 0;
				frameObj = frames[_name + getZeros(o.counter)];
			}

			//bmp.x = -hero.x + (stage.stageWidth / 2);
			//bmp.y = -hero.y + (stage.stageHeight / 2);
			var heroPosX: int = -hero.x + (stage.stageWidth / 2);
			var heroPosY: int = -hero.y + (stage.stageHeight / 2);

			if (frameObj) {
				var list: Object = frameObj.frame;
				outer: for (var row: int = 0; row < list.h; row++) {
					for (var col: int = 0; col < list.w; col++) {
						var pixel: uint = src.getPixel(list.x + col, list.y + row);
						if (pixel != 0x000000) {
							//trace(pixel);
							if(pixel == 0x78b7dd )//|| pixel == 0xcccccc
							{
								pixel = o.color;
							}
							var _x: Number = heroPosX + o.x + col;
							var _y: Number = heroPosY + o.y + row;
							if (_x + list.w < 0 || _x - list.w > stage.stageWidth || _y + list.h < 0 || _y > stage.stageHeight) {
								break outer;
							}
							bd.setPixel(_x, _y, pixel);
						}


					}
				}
			}


		}




		function moveHero(): void {
			var rot: Number = cam.currRot_deg;


			var state: String = "IDLE_";
			dir = "";
			hero.walking = false;

			if (Model.W) {
				hero.y -= runSpeed;
				hero.walking = true;
				state = "WALK_";
				dir += "N";
			}

			if (Model.S) {
				hero.y += runSpeed;
				hero.walking = true;
				state = "WALK_";
				dir += "S";
			}

			if (Model.A) {
				hero.x -= runSpeed;
				hero.walking = true;
				state = "WALK_";
				dir += "W";
			}

			if (Model.D) {
				hero.x += runSpeed;
				hero.walking = true;
				state = "WALK_";
				dir += "E";
			}

			if (dir == "") {
				dir = "S";
			}


			//if (hero.prevState != state + dir) {
			setAnimFrame(state + dir, hero);
			//hero.pawn.gotoAndStop(state + dir);
			//}
			hero.prevState = state + dir;


			//bmp.x = -hero.x + (stage.stageWidth / 2);
			//bmp.y = -hero.y + (stage.stageHeight / 2);
		}


		function moveParticles(o: Object, fromHero: Boolean = false): void {
			var i: int = 0;
			var o: Object;
			var c: Object;
			var row: int;
			var col: int;
			var start: int = -1;
			var end: int = 2;


			var spread: int = blockSize / 4;
			if (fromHero) {
				start = -spread;
				end = spread;
			}

			for (row = start; row < end; row++) {
				for (col = start; col < end; col++) {

					var key: String = (o.row + row) + "_" + (o.col + col);

					var a: Array = map[key];
					if (a) {
						a.sortOn("y", Array.NUMERIC);
						for (var j: int = 0; j < a.length; j++) {

							c = a[j];


							if (c == o) {
								continue;
							}

							if (c == hero) {
								continue;
							}

							if (o.movers == undefined || o.movers == null) {
								o.movers = [];
							}

							if (c.movers == undefined || c.movers == null) {
								c.movers = [];
							}

							//if this circle is being moved by the one it is trying to move - do nothing
							if (o.movers.indexOf(c) != -1) {
								continue;
							}

							if (c.movers.indexOf(o) != -1) {
								continue;
							}

							var dist: Number = getDistance(c.x, c.y, o.x, o.y);

							var minDist: Number = c.size + o.size;
							var h: Number = c.y - o.y;
							var w: Number = c.x - o.x;
							var dirX: Number = w / dist;
							var dirY: Number = h / dist;

							//var angle: Number = Math.atan2(c.y - o.y, c.x - o.x);
							//var dirX: Number = Math.cos(angle);
							//var dirY: Number = Math.sin(angle); //do this better

							if (dist < minDist) {


								c.inRange = true;


								var per: Number = 1 - (dist / minDist);


								c.x = o.x + dirX * (minDist);
								c.y = o.y + dirY * (minDist);



								if (!c.movers) {
									c.movers = [];
								}
								c.movers.push(o);
								moveParticles(c);
							}
							/*
					else
					{
						if(c.moved = false)
						{
							if(dist > (minDist * 1.5) && dist < (minDist * 5))
							{
								angle = Math.atan2(c.y - hero.y, c.x - hero.x);
								dirX = Math.cos(angle);
								dirY = Math.sin(angle);
								c.x -=  dirX ;
								c.y -=  dirY ;
								c.moved = true;
							}
						}
						
					}*/
						}
					}
				}
			}
		}


		function update(e: Event): void {
			map = {};
			bd.fillRect(new Rectangle(0, 0, stage.stageWidth, stage.stageHeight), 0x666666);
			bd.lock();
			moveHero();
			//hero.x = mouseX;
			//hero.y = mouseY;


			var i: int = 0;
			var o: Object;
			var c: Object;
			var row: int;
			var col: int;

			for (i = 0; i < numParticles; i++) {
				o = arr[i];
				row = o.y / blockSize;
				col = o.x / blockSize;
				o.row = row;
				o.col = col;
				o.movers = null;
				o.inRange = false;
				o.moved = false;
				if (!map[row + "_" + col]) {
					map[row + "_" + col] = [];
				}
				map[row + "_" + col].push(o);
			}


			//g.clear();

			moveParticles(hero, true);


			/**/
			var spread: int = blockSize / 4;
			for (row = hero.row - spread; row <= hero.row + spread; row++) {
				for (col = hero.col - spread; col <= hero.col + spread; col++) {
					var a: Array = map[row + "_" + col];
					if (a) {
						for (var j: int = 0; j < a.length; j++) {
							o = a[j];



							if (o != hero) {
								var state: String = "IDLE_";
								if (o.inRange) {
									if (hero.walking) {
										state = "WALK_";
									}
								}
								var dir: String = getDirection(o.x, o.y, hero.x, hero.y);
								/*
						if (hero.walking) {
							if (dir == "N") {
								dir = "S";
							}
							if (dir == "NE") {
								dir = "SW";
							}
							if (dir == "SW") {
								dir = "NE";
							}
							if (dir == "NW") {
								dir = "SE";
							}
							if (dir == "SE") {
								dir = "NW";
							}
							if (dir == "S") {
								dir = "N";
							}
							if (dir == "E") {
								dir = "W";
							}
							if (dir == "W") {
								dir = "E";
							}
						}
						*/

								setAnimFrame(state + dir, o);
								o.prevState = state + dir;

							}



						}
					}

				}
			}


			bd.unlock();

			//stage.removeEventListener(Event.ENTER_FRAME, update);


		}


		function myKeyDown(e: KeyboardEvent): void {

			if (e.keyCode == Keyboard.UP) {
				Model.up = true;
				Model.down = false;
			}
			if (e.keyCode == Keyboard.DOWN) {

				Model.down = true;
				Model.up = false;
			}
			if (e.keyCode == Keyboard.LEFT) {

				Model.left = true;
				Model.right = false;
			}
			if (e.keyCode == Keyboard.RIGHT) {

				Model.right = true;
				Model.left = false;
			}


			if (e.keyCode == Keyboard.W) {
				Model.W = true;
			}
			if (e.keyCode == Keyboard.A) {
				Model.A = true;
			}

			if (e.keyCode == Keyboard.S) {
				Model.S = true;
			}

			if (e.keyCode == Keyboard.D) {
				Model.D = true;
			}

		}




		function myKeyUp(e: KeyboardEvent): void {

			if (e.keyCode == Keyboard.UP) {
				Model.up = false;
			}
			if (e.keyCode == Keyboard.DOWN) {

				Model.down = false;
			}
			if (e.keyCode == Keyboard.LEFT) {

				Model.left = false;
			}
			if (e.keyCode == Keyboard.RIGHT) {

				Model.right = false;
			}


			if (e.keyCode == Keyboard.W) {
				Model.W = false;
			}
			if (e.keyCode == Keyboard.A) {
				Model.A = false;
			}

			if (e.keyCode == Keyboard.S) {
				Model.S = false;
			}

			if (e.keyCode == Keyboard.D) {
				Model.D = false;
			}

		}

		function correctAngle(_angleDeg: Number): Number {
			while (_angleDeg < 0) {
				_angleDeg += 360;
			}

			while (_angleDeg > 360) {
				_angleDeg -= 360;
			}

			return _angleDeg;
		}

		function radToDegrees(rads: Number): Number {
			return rads * 180 / Math.PI
		}

		function degreesToRad(degs: Number): Number {
			return degs * Math.PI / 180;
		}


		function getAngle(from: Object, to: Object): Number {
			var angle: Number = Math.atan2(to.y - from.y, to.x - from.x);
			return angle;
		}

		function getDistance(p1X: Number, p1Y: Number, p2X: Number, p2Y: Number): Number {

			var dX: Number = p1X - p2X;
			var dY: Number = p1Y - p2Y;
			var dist: Number = Math.sqrt(dX * dX + dY * dY);
			return dist;
		}


		function getDirection(p1X: Number, p1Y: Number, p2X: Number, p2Y: Number): String {


			var firstDir: String = "";
			var secondDir: String = "";

			//////////////////////
			var degrees: int = Math.atan2(p1Y - p2Y, p1X - p2X) / Math.PI * 180;

			while (degrees >= 360) {
				degrees -= 360;
			}
			while (degrees < 0) {
				degrees += 360;
			}


			degrees = Math.ceil(degrees);

			if (degrees >= 66 && degrees < 112) {
				firstDir = "N";
			}
			if (degrees >= 22 && degrees < 66) {
				firstDir = "N";
				secondDir = "W";
			}

			if (degrees >= 0 && degrees < 22) {
				secondDir = "W";
			}

			if (degrees >= 337 && degrees <= 359) {
				secondDir = "W";
			}
			if (degrees >= 292 && degrees < 337) {
				firstDir = "S";
				secondDir = "W";
			}
			if (degrees >= 247 && degrees < 292) {
				firstDir = "S";
			}
			if (degrees >= 202 && degrees < 247) {
				firstDir = "S";
				secondDir = "E";
			}
			if (degrees >= 157 && degrees < 202) {
				secondDir = "E";
			}

			if (degrees >= 112 && degrees < 157) {
				firstDir = "N";
				secondDir = "E";
			}


			return firstDir + "" + secondDir;
		}

	}

}