def coordToArray(x, y):
    board = [[0]*768 for _ in range(1024)]
    board[x][y] = 1
    return board
print('board', coordToArray(27, 175))