module Main exposing (main)

import Browser
import Browser.Events
import Json.Decode as Decode
import Process
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Task
import Random

-- all models
type alias Model =
  { ball : Ball
  , rPaddle : Paddle
  , lPaddle : Paddle
  , rPaddleMovement : PaddleMovement
  , lPaddleMovement : PaddleMovement
  , gameStatus : GameStatus
  , score : Score
  , seed : Random.Seed
  }

-- ball model
type alias Ball =
  { x : Int
  , y : Int
  , radius : Int
  , hSpeed : Int
  , vSpeed : Int
  }
-- paddle attributes
type alias PaddleInfo =
  { x : Int
  , y : Int
  , width : Int
  , height : Int
  }
-- players scores
type alias Score =
  { rightPlayerScore : Int
  , leftPlayerScore : Int
  }
-- for input from index file
type alias Flags =
    Float

-- custom types

-- paddle objects
type Paddle
    = RightPaddle PaddleInfo
    | LeftPaddle PaddleInfo

-- in progress or someone scored
type GameStatus
  = InProgress
  | Winner Player

-- messages
type Msg
    = OnAnimationFrame Float
    | KeyDown PlayerInput
    | KeyUp PlayerInput
    | Restart
    | NewWinner Player

-- key stroke types
type PlayerInput
    = RightPaddleUp
    | RightPaddleDown
    | LeftPaddleUp
    | LeftPaddleDown

-- paddle objects' states
type PaddleMovement
    = Up
    | Down
    | Idle

-- player objects
type Player
  = LeftPlayer
  | RightPlayer

-- INIT

-- for spawning position + speed
randomVSpeed : Random.Seed -> ( Int, Random.Seed )
randomVSpeed seed =
  Random.step (Random.int -10 10) seed

init : Flags -> ( Model, Cmd Msg )
init seed = -- seed being the random flag input from html file
  let
    initialSeed =
      seed
        |> (*) 100
        |> round
        |> Random.initialSeed

    ( initVSpeed , newSeed ) =
      randomVSpeed initialSeed

    -- assign the initial spawn speed to the ball
    initialBall =
      { initBall | vSpeed = initVSpeed }

  -- initial game screen setup
  in
  ( { ball = initialBall
    , rPaddle = RightPaddle <| initPaddle 480 -- x-pos 480
    , lPaddle = LeftPaddle <| initPaddle 10 -- x-pos 10
    , rPaddleMovement = Idle
    , lPaddleMovement = Idle
    , gameStatus = InProgress
    , score =
        { rightPlayerScore = 0
        , leftPlayerScore = 0
        }
    , seed = newSeed
    }
  , Cmd.none
  )

-- ball attributes
initBall : Ball
initBall =
  { x = 250
  , y = 250
  , radius = 8
  , hSpeed = 4
  , vSpeed = 2
  }
-- paddle attributes
initPaddle : Int -> PaddleInfo
initPaddle initX =
  { x = initX
  , y = 225
  , width = 10
  , height = 50
  }

-- make calls to init, view, update
main : Program Flags Model Msg
main =
  -- receive events from Browser
  Browser.element
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions -- for frame + input event related data
    }

-- UPDATE

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    OnAnimationFrame timeDelta ->
      let
        updatedBall =
          updateBall model
        -- update ball and paddles
        updatedModel =
          { model
          | ball = updatedBall
          , rPaddle = updatePaddle model.rPaddleMovement model.rPaddle
          , lPaddle = updatePaddle model.lPaddleMovement model.lPaddle
          }
      -- update game status
      in
      case ( maybeWinner updatedBall, model.gameStatus ) of
        -- if there's a winner, return call to update
        ( Just player, InProgress ) ->
          update (NewWinner player) updatedModel
        -- if not, just return the updated models
        _ ->
          ( updatedModel, Cmd.none )

    -- restart, update the score, small pause before respawning the ball
    NewWinner player ->
      let
        alwaysRestart : a -> Msg
        alwaysRestart =
          always Restart

        updatedScore =
          updateScores model.score player

        -- small delay before restart
        sleepCmd =
          Process.sleep 500
            |> Task.perform alwaysRestart

      -- model updates
      in
      ( { model
          | gameStatus = Winner player
          , score = updatedScore
        }
      , sleepCmd
      )

    -- when a valid key is pressed, change the respective paddle position
    KeyDown playerInput ->
      case playerInput of
        RightPaddleUp ->
          ( { model | rPaddleMovement = Up }
          , Cmd.none
          )
        RightPaddleDown ->
          ( { model | rPaddleMovement = Down }
          , Cmd.none
          )
        LeftPaddleUp ->
          ( { model | lPaddleMovement = Up }
          , Cmd.none
          )
        LeftPaddleDown ->
          ( { model | lPaddleMovement = Down }
          , Cmd.none
          )

    -- restart at random speed
    Restart ->
      let
        ( vSpeed, newSeed ) =
          randomVSpeed model.seed

        -- aimed toward last loser
        newDirection =
          case model.gameStatus of
            Winner RightPlayer ->
              -1
            _ ->
              1

        ball =
          { initBall
              | vSpeed = vSpeed
              , hSpeed = initBall.hSpeed * newDirection
          }
      in
      ( { model
          | ball = ball
          , gameStatus = InProgress
          , seed = newSeed
        }
      , Cmd.none
      )

    -- so that the paddles don't move "automatically" / without player input
    KeyUp playerInput ->
      case playerInput of
        RightPaddleUp ->
          ( { model | rPaddleMovement = Idle }
          , Cmd.none
          )
        RightPaddleDown ->
          ( { model | rPaddleMovement = Idle }
          , Cmd.none
          )
        LeftPaddleUp ->
          ( { model | lPaddleMovement = Idle }
          , Cmd.none
          )
        LeftPaddleDown ->
          ( { model | lPaddleMovement = Idle }
          , Cmd.none
          )

updateBall :
  -- extensible record for noting important arguments + return
  { a
      | gameStatus : GameStatus
      , ball : Ball
      , rPaddle : Paddle
      , lPaddle : Paddle
  }
  -> Ball
updateBall { gameStatus, ball, rPaddle, lPaddle } =
  let
    -- checking if the ball was hit at an angle by a paddle
    maybeAngleBounceRight =
      bounceDistance rPaddle ball

    maybeAngleBounceLeft =
      bounceDistance lPaddle ball

    maybeAngleBounce =
      if maybeAngleBounceRight == Nothing then
        maybeAngleBounceLeft
      else
        maybeAngleBounceRight

    -- if the ball was hit at an angle, change the vertical speed
    -- otherwise, leave it the same
    ( hSpeed, bouncedVSpeed ) =
      case maybeAngleBounce of
        Nothing ->
          ( ball.hSpeed, ball.vSpeed )
        Just distance ->
          ( ball.hSpeed * -1
          , distance // 10
          )

    -- if the ball hits the wall...
    shouldBounceOffWall =
      bounceOffWallCheck ball

    -- ...change direction
    vSpeed =
      if shouldBounceOffWall then
        bouncedVSpeed * -1
      else
        bouncedVSpeed
  in
  -- if the games in progress, continuously update the ball attributes
  case gameStatus of
    Winner _ ->
      ball
    InProgress ->
      { ball
          | x = ball.x + hSpeed
          , y = ball.y + vSpeed
          , hSpeed = hSpeed
          , vSpeed = vSpeed
      }


-- move the paddle based on user input
updatePaddle : PaddleMovement -> Paddle -> Paddle
updatePaddle movement paddle =
  let
    amount =
      case movement of
        Up ->
          -10
        Down ->
          10
        Idle ->
          0
  in
  case paddle of
    -- clamp function ensures the boundaries of the top/bottom game walls
    -- making sure the paddles dont go off screen
    RightPaddle paddleInfo ->
      { paddleInfo
          | y =
            paddleInfo.y
                + amount
                |> clamp 0 (500 - paddleInfo.height)
      }
        |> RightPaddle

    LeftPaddle paddleInfo ->
      { paddleInfo
          | y =
            paddleInfo.y
                + amount
                |> clamp 0 (500 - paddleInfo.height)
      }
        |> LeftPaddle

-- bounce off paddles
bounceDistance : Paddle -> Ball -> Maybe Int
bounceDistance paddle ball =
  let
    normalize : Int -> Int -> Int
    normalize distance height =
      -- calculating angle
      (distance - (height // 2)) * 100 // (height // 2)
  in
  case paddle of
    LeftPaddle { x, y, width, height } ->
      if
        (ball.x <= x + width)
          && (ball.y >= y)
          && (ball.y <= y + height)
          && (ball.hSpeed < 0) --ensures that the ball doesnt get stuck
      then
        Just <| normalize (ball.y - y) height
      else
        Nothing

    RightPaddle { x, y, height } ->
      if
        (ball.x + ball.radius >= x)
          && (ball.y >= y)
          && (ball.y <= y + height)
          && (ball.hSpeed > 0) -- also ensures that the ball doesnt get stuck
      then
        Just <| normalize (ball.y - y) height
      else
        Nothing

-- bounce off walls
bounceOffWallCheck : Ball -> Bool
bounceOffWallCheck ball =
  let
    radius =
      ball.radius
  in
  ball.y <= radius || ball.y >= (500 - radius)

-- if the ball is behind the left/right paddle, the opposing player wins
maybeWinner : Ball -> Maybe Player
maybeWinner ball =
  if ball.x <= ball.radius then
    Just RightPlayer
  else if ball.x >= (500 - ball.radius) then
    Just LeftPlayer
  else
    Nothing

-- updating score based on a provided winner + preexisting score
updateScores : Score -> Player -> Score
updateScores score winner =
  case winner of
    RightPlayer ->
      { score | rightPlayerScore = score.rightPlayerScore + 1 }
    LeftPlayer ->
      { score | leftPlayerScore = score.leftPlayerScore + 1 }

-- VIEW

view : Model -> Svg.Svg Msg
view { ball, rPaddle, lPaddle, score } =
  -- create the playing field
  svg
    [ width "500"
    , height "500"
    , viewBox "0 0 500 500"
    , Svg.Attributes.style "background: #add8e6"
    ]
    -- display ball and paddles
    [ viewDivider
    , viewBall ball
    , viewPaddle rPaddle
    , viewPaddle lPaddle
    , viewScore score
    ]

-- the "net" in the middle
viewDivider : Svg.Svg Msg
viewDivider =
  line
    [ x1 "249"
    , y1 "0"
    , x2 "249"
    , y2 "500"
    , stroke "black"
    , strokeDasharray "4"
    , strokeWidth "4"
    ]
    []

-- the ball
viewBall : Ball -> Svg.Svg Msg
viewBall { x, y, radius } =
     circle
         [ cx <| String.fromInt x
         , cy <| String.fromInt y
         , r <| String.fromInt radius
         ]
         []

-- the paddles
viewPaddle : Paddle -> Svg.Svg Msg
viewPaddle paddle =
  let
    paddleInfo =
      case paddle of
        LeftPaddle info ->
            info
        RightPaddle info ->
            info
  in
  rect
      [ x <| String.fromInt paddleInfo.x
      , y <| String.fromInt paddleInfo.y
      , width <| String.fromInt paddleInfo.width
      , height <| String.fromInt paddleInfo.height
      ]
      []

-- the score
viewScore : Score -> Svg.Svg Msg
viewScore score =
  g
  -- display the score
  [ fontSize "100px"
  , fontFamily "Marker Felt"
  , color "white"
  ]
  [ text_ [ x "100", y "100", textAnchor "start" ]
    [ text <| String.fromInt score.leftPlayerScore ]
  , text_ [ x "400", y "100", textAnchor "end" ]
    [ text <| String.fromInt score.rightPlayerScore ]
  ]

-- provides an event— keyboard events, animation frames 
subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
    [ Browser.Events.onAnimationFrameDelta OnAnimationFrame
    -- attach the decoded string from user input to the KeyDown
    , Browser.Events.onKeyDown (Decode.map KeyDown keyDecoder)
    , Browser.Events.onKeyUp (Decode.map KeyUp keyDecoder)
    ]

keyDecoder : Decode.Decoder PlayerInput
keyDecoder =
  -- returns a decoder, which is then passed to keyToPlayerInput to determine validity
  Decode.field "key" Decode.string
    |> Decode.andThen keyToPlayerInput

keyToPlayerInput : String -> Decode.Decoder PlayerInput
-- valid input affects the game through custom types
keyToPlayerInput keyString =
  case keyString of
    "ArrowUp" ->
      Decode.succeed RightPaddleUp
    "ArrowDown" ->
      Decode.succeed RightPaddleDown
    "w" ->
      Decode.succeed LeftPaddleUp
    "s" ->
      Decode.succeed LeftPaddleDown
    _ ->
      Decode.fail "not a valid player control"
