import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart';

// images available
enum ImageType {
  zero,
  one,
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  bomb,
  facingDown,
  flagged,
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minesweeper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GameActivity(),
    );
  }
}

class GameActivity extends StatefulWidget {
  @override
  _GameActivityState createState() => _GameActivityState();
}

class _GameActivityState extends State<GameActivity> {
  // number of rows and columns
  static const rowCount = 13;
  static const columnCount = 30;

  // grid of squares
  List<List<BoardSquare>> board = [];

  // squares that have been clicked already
  List<bool> openedSquares = [];

  // flagged squares
  List<bool> flaggedSquares = [];

  // number of bombs
  static const bombCount = 40;

  // number of squares left to click
  int squaresLeft = rowCount * columnCount;

  // number of clicks
  int numClicks = 0;

  @override
  void initState() {
    super.initState();
    document.onContextMenu.listen((event) => event.preventDefault());
    _initializeGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: <Widget>[
          Container(
            color: Colors.grey,
            height: 60.0,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                InkWell(
                  onTap: () {
                    _initializeGame();
                  },
                  child: CircleAvatar(
                    child: Icon(
                      Icons.tag_faces,
                      color: Colors.black,
                      size: 40.0,
                    ),
                    backgroundColor: Colors.yellowAccent,
                  ),
                )
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnCount,
            ),
            itemBuilder: (context, position) {
              int rowNumber = (position / columnCount).floor();
              int columnNumber = (position % columnCount);

              Image image;

              if (openedSquares[position] == false) {
                if (flaggedSquares[position] == true) {
                  image = getImage(ImageType.flagged);
                } else {
                  image = getImage(ImageType.facingDown);
                }
              } else {
                if (board[rowNumber][columnNumber].hasBomb) {
                  image = getImage(ImageType.bomb);
                } else {
                  image = getImage(
                    getImageTypeFromNumber(
                      board[rowNumber][columnNumber].bombsAround,
                    ),
                  );
                }
              }

              return InkWell(
                onTap: () {
                  ++numClicks;
                  if (numClicks == 1 &&
                      board[rowNumber][columnNumber].hasBomb) {
                    board[rowNumber][columnNumber].hasBomb = false;
                    board[0][0].hasBomb = true;
                  }
                  if (board[rowNumber][columnNumber].hasBomb) {
                    _handleGameOver();
                  }
                  if (board[rowNumber][columnNumber].bombsAround == 0) {
                    _handleTap(rowNumber, columnNumber);
                  } else {
                    setState(() {
                      openedSquares[position] = true;
                      --squaresLeft;
                    });
                  }

                  if (squaresLeft <= bombCount) {
                    _handleWin();
                  }
                },
                onLongPress: () {
                  if (openedSquares[position] == false) {
                    setState(() {
                      flaggedSquares[position] = true;
                    });
                  }
                },
                splashColor: Colors.grey,
                child: Listener(
                  child: Container(
                    color: Colors.grey,
                    child: image,
                  ),
                  onPointerDown: (PointerDownEvent details) {
                    if (details.kind == PointerDeviceKind.mouse &&
                        details.buttons == kSecondaryMouseButton) {
                      if (flaggedSquares[position]) {
                        setState(() {
                          flaggedSquares[position] = false;
                        });
                      } else if (!openedSquares[position]) {
                        setState(() {
                          flaggedSquares[position] = true;
                        });
                      }
                    }
                  },
                ),
              );
            },
            itemCount: rowCount * columnCount,
          ),
        ],
      ),
    );
  }

  // initialize all lists
  void _initializeGame() {
    // initialize all squares with no bombs
    board = List.generate(rowCount, (i) {
      return List.generate(columnCount, (j) {
        return BoardSquare();
      });
    });

    // init opened squares
    openedSquares = List.generate(rowCount * columnCount, (i) => false);

    // init flagged squares
    flaggedSquares = List.generate(rowCount * columnCount, (i) => false);

    // reset bomb count
    squaresLeft = rowCount * columnCount;

    numClicks = 0;

    // randomly generate bombs
    for (int tempBombCount = 0; tempBombCount < bombCount;) {
      Random random = new Random();
      int i = random.nextInt(rowCount);
      int j = random.nextInt(columnCount);
      if (!board[i][j].hasBomb) {
        // bomb cant be at top left
        if (i == 0 && j == 0) continue;

        board[i][j].hasBomb = true;
        ++tempBombCount;

        // update bombs around
        bool isTopRow = i == 0;
        bool isBottomRow = i == rowCount - 1;
        bool isLeftCol = j == 0;
        bool isRightCol = j == columnCount - 1;

        if (!isTopRow) ++board[i - 1][j].bombsAround;
        if (!isBottomRow) ++board[i + 1][j].bombsAround;
        if (!isLeftCol) ++board[i][j - 1].bombsAround;
        if (!isRightCol) ++board[i][j + 1].bombsAround;
        if (!isTopRow && !isLeftCol) ++board[i - 1][j - 1].bombsAround;
        if (!isTopRow && !isRightCol) ++board[i - 1][j + 1].bombsAround;
        if (!isBottomRow && !isLeftCol) ++board[i + 1][j - 1].bombsAround;
        if (!isBottomRow && !isRightCol) ++board[i + 1][j + 1].bombsAround;
      }
    }
    setState(() {});
  }

  int idx(int i, int j) {
    return (i * columnCount) + j;
  }

  void _handleTap(int i, int j) {
    int position = idx(i, j);
    openedSquares[position] = true;
    --squaresLeft;

    if (board[i][j].bombsAround == 0) {
      bool isTopRow = i == 0;
      bool isBottomRow = i == rowCount - 1;
      bool isLeftCol = j == 0;
      bool isRightCol = j == columnCount - 1;

      if (!isTopRow) {
        if (!board[i - 1][j].hasBomb && !openedSquares[idx(i - 1, j)])
          _handleTap(i - 1, j);
      }
      if (!isBottomRow) {
        if (!board[i + 1][j].hasBomb && !openedSquares[idx(i + 1, j)])
          _handleTap(i + 1, j);
      }
      if (!isLeftCol) {
        if (!board[i][j - 1].hasBomb && !openedSquares[idx(i, j - 1)])
          _handleTap(i, j - 1);
      }
      if (!isRightCol) {
        if (!board[i][j + 1].hasBomb && !openedSquares[idx(i, j + 1)])
          _handleTap(i, j + 1);
      }
      if (!isTopRow && !isLeftCol) {
        if (!board[i - 1][j - 1].hasBomb && !openedSquares[idx(i - 1, j - 1)])
          _handleTap(i - 1, j - 1);
      }
      if (!isTopRow && !isRightCol) {
        if (!board[i - 1][j + 1].hasBomb && !openedSquares[idx(i - 1, j + 1)])
          _handleTap(i - 1, j + 1);
      }
      if (!isBottomRow && !isLeftCol) {
        if (!board[i + 1][j - 1].hasBomb && !openedSquares[idx(i + 1, j - 1)])
          _handleTap(i + 1, j - 1);
      }
      if (!isBottomRow && !isRightCol) {
        if (!board[i + 1][j + 1].hasBomb && !openedSquares[idx(i + 1, j + 1)])
          _handleTap(i + 1, j + 1);
      }
    }

    setState(() {});
  }

  void _handleGameOver() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Game Over!"),
          content: Text("You stepped on a mine!"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                _initializeGame();
                Navigator.pop(context);
              },
              child: Text("Play Again"),
            ),
          ],
        );
      },
    );
  }

  void _handleWin() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Congratulations!"),
          content: Text("You Win!"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                _initializeGame();
                Navigator.pop(context);
              },
              child: Text("Play Again"),
            ),
          ],
        );
      },
    );
  }

  Image getImage(ImageType type) {
    switch (type) {
      case ImageType.zero:
        return Image.asset('images/0.png');
      case ImageType.one:
        return Image.asset('images/1.png');
      case ImageType.two:
        return Image.asset('images/2.png');
      case ImageType.three:
        return Image.asset("images/3.png");
      case ImageType.four:
        return Image.asset("images/4.png");
      case ImageType.five:
        return Image.asset("images/5.png");
      case ImageType.six:
        return Image.asset("images/6.png");
      case ImageType.seven:
        return Image.asset("images/7.png");
      case ImageType.eight:
        return Image.asset("images/8.png");
      case ImageType.bomb:
        return Image.asset("images/bomb.png");
      case ImageType.facingDown:
        return Image.asset("images/facingDown.png");
      case ImageType.flagged:
        return Image.asset("images/flagged.png");
      default:
        return Image.asset("images/0.png");
    }
  }

  ImageType getImageTypeFromNumber(int number) {
    switch (number) {
      case 0:
        return ImageType.zero;
      case 1:
        return ImageType.one;
      case 2:
        return ImageType.two;
      case 3:
        return ImageType.three;
      case 4:
        return ImageType.four;
      case 5:
        return ImageType.five;
      case 6:
        return ImageType.six;
      case 7:
        return ImageType.seven;
      case 8:
        return ImageType.eight;
      default:
        return ImageType.zero;
    }
  }
}

class BoardSquare {
  // true if current square has bomb
  bool hasBomb;
  // number of bombs around current square
  int bombsAround;

  BoardSquare({this.hasBomb = false, this.bombsAround = 0});
}
