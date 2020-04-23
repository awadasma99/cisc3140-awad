// requestAnimationFrame functions like setTimeout in that it will
// call your callback at approx 60 frames per second, its better
// in the sene that it can perform optimizations on the call
var animate = window.requestAnimationFrame ||
        window.webkitRequestAnimationFrame ||
        window.mozRequestAnimationFrame ||
        function(callback) { window.setTimeout(callback, 1000/60) };

var canvas = document.createElement('canvas');
var width = 400;
var height = 600;
canvas.width = width;
canvas.height= height;
var context  = canvas.getContext('2d');

// when the page loads, attach the canvas to the screen
window.onload = function() {
  document.body.appendChild(canvas);
  //call a step function using the animate method
  animate(step);
};

// step function will do three things
// 1) update the objects (paddles, ball)
// 2) render those objects
// 3) use the requestAnimationFrame to call step again

var step = function() {
  update();
  render();
  animate(step);
};

var update = function() {
  // allow the player to move their paddle
  player.update();

  // animate the computer's paddle
  computer.update(ball);

  // animate the ball
  ball.update(player.paddle, computer.paddle);
};

var render = function() {
  context.fillStyle = "A9F9E3";
  context.fillRect(0, 0, width, height);

  drawText(player.score, canvas.width/2 - 25, 400);
  drawText(computer.score, canvas.width/2 - 25, 200);
  
  player.render();
  computer.render();
  ball.render();
};

function drawText(text, x, y){
    context.fillStyle = "#FFF";
    context.font = "75px fantasy";
    context.fillText(text, x, y);
}

// creates the paddle object
function Paddle(x, y, width, height) {
  this.x = x;
  this.y = y;
  this.width = width;
  this.height = height;
  this.x_speed = 0;
  this.y_speed = 0;
}

// how the paddle is displayed
Paddle.prototype.render = function() {
  context.fillStyle = "000000";
  context.fillRect(this.x, this.y, this.width, this.height);
};

//how the player's paddle moves
Paddle.prototype.move = function(x, y) {
  this.x += x;
  this.y += y;
  this.x_speed = x;
  this.y_speed = y;

  // check if the ball is far left
  if (this.x < 0) {
    this.x = 0;
    this.x_speed = 0;
  }

  // check if the ball is far right
  else if (this.x + this.width > 400) {
    this.x = 400 - this.width;
    this.x_speed = 0;
  }
};

// create the player and computer paddles separately, since
// they operate independently

function Player() {
  this.paddle = new Paddle(175, 580, 50, 10);
  this.score = 0;
}

function Computer() {
  this.paddle = new Paddle(175, 10, 50, 10);
  this.score = 0;
}

// render the two paddles
Player.prototype.render = function() {
  this.paddle.render();
};

// allow player to move their paddle
Player.prototype.update = function() {
  for (var key in keysDown) {
    var value = Number(key);
    // left arrow key
    if (value == 37) {
      this.paddle.move(-4, 0);
    }
    // right arrow key
    else if (value == 39) {
      this.paddle.move(4, 0);
    }
    // other
    else {
      this.paddle.move(0, 0);
    }
  }
};

Computer.prototype.render = function() {
  this.paddle.render();
};

Computer.prototype.update = function(ball) {
  var x_pos = ball.x;
  // distance between the ball and computer's paddle
  var diff = -((this.paddle.x + (this.paddle.width / 2)) - x_pos);

  if (diff < 0 && diff < -4) {
    diff = -5;
  }
  else if (diff > 0 && diff > 4) {
    diff = 5;
  }
  this.paddle.move(diff, 0);
  if (this.paddle.x < 0) {
    this.paddle.x = 0;
  }
  else if (this.paddle.x + this.paddle.width > 400) {
    this.paddle.x = 400 - this.paddle.width;
  }
};

// create the ball
function Ball(x, y) {
  this.x = x;
  this.y = y;
  this.x_speed = 0;
  this.y_speed = 3;
  this.radius = 5;
}

Ball.prototype.render = function() {
  context.beginPath();
  context.arc(this.x, this.y, this.radius, 2 * Math.PI, false);
  context.fillStyle = "#000000";
  context.fill();
};

Ball.prototype.update = function(paddle1, paddle2) {
  // make the ball move toward the player's paddle
  this.x += this.x_speed;
  this.y += this.y_speed;
  var top_x = this.x - 5;
  var top_y = this.y - 5;
  var bottom_x = this.x + 5;
  var bottom_y = this.y + 5;

  //check if it hits the left wall, if so, make it bounce off
  if (this.x - 5 < 0) {
    this.x = 5;
    this.x_speed = -this.x_speed;
  }
  // check if it hits the right wall, if so, make it bounce off
  else if (this.x + 5 > 400) {
    this.x = 395;
    this.x_speed = -this.x_speed;
  }

  // if the ball surpasses the top/bottom, reset
  if (this.y < 0) {
    this.x_speed = 0;
    this.y_speed = 3;
    this.x = 200;
    this.y = 300;
    player.score += 1;
  }
  if (this.y > 600) {
    this.x_speed = 0;
    this.y_speed = 3;
    this.x = 200;
    this.y = 300;
    computer.score += 1;
  }

  // hit the player's paddle
  if (top_y > 300) {
    if (top_y < (paddle1.y + paddle1.height) && bottom_y > paddle1.y && top_x < (paddle1.x + paddle1.width) && bottom_x > paddle1.x) {
      this.y_speed = -3;
      // the paddle's speed determines the ball's speed
      this.x_speed += (paddle1.x_speed / 2);
      this.y += this.y_speed;
    }
  }
    // hit the computer's paddle
    else {
      if (top_y < (paddle2.y + paddle2.height) && bottom_y > paddle2.y && top_x < (paddle2.x + paddle2.width) && bottom_x > paddle2.x) {
        this.y_speed = 3;
        // the paddle's speed determines the ball's speed
        this.x_speed += (paddle2.x_speed / 2);
        this.y += this.y_speed;
      }
    }
};

// render everything on the screen (render method above)
var player = new Player();
var computer = new Computer();
var ball = new Ball(200, 300);

var keysDown = {};

// keeps track of which key is pressed
window.addEventListener("keydown", function(event) {
  keysDown[event.keyCode] = true;
});

window.addEventListener("keyup", function(event) {
  delete keysDown[event.keyCode];
});
