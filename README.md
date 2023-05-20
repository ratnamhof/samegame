
# introduction

Win the game by removing a target number of tiles from the board. Groups of at least 2 or 3 (depending on the game version) connected tiles of the same color can be removed. All tiles above an empty area left by removing a block will drop down. Empty columns will be filled by the columns to the right of it.

The only check that is performed in the game is if there are still valid moves available, not if the complete board can be cleared.

If a seed is provided that would result in a board without valid moves a new board will automatically be generated.

# command line options

```
samegame [-gh] [-cdefghjmnrstv value]

  -c,--columns     integer representing the nr of columns (minimum:2)
  -d,--ntiles      integer representing the number of dropping tiles in flood game
  -e,--emptyrows   integer representing the nr of empty rows in flood game
  -f,--dropfreq    integer representing the frequency of blocks dropping in flood game
  -g,--gameversion list available game versions
  -h,--help        display this help text
  -j,--jokerfreq   integer representing the frequency of joker rewards in flood game
  -m,--minsize     integer representing the minimum nr of connected tiles
                   required for removal
  -n,--ncolors     integer in set [2-8] representing the nr of colors
  -r,--rows        integer representing the nr of rows (minimum:2)
  -s,--seed        integer seed for the pseudo-random number generator
  -t,--tileset     string in the set {colors,letters,chars}
  -v,--version     integer or string indicating the game version
```

# game versions

The game experience can be changed by selecting different board settings. Some default choices have been made available through the game version option as enumerated below.

## chain shot

Board layout of the Chain Shot! game, i.e. 20x10 with 4 colors. Minimum required number of connected tiles for removal is 2. Goal of the game is to clear the entire board of colored tiles.

## same game

Large board layout of the SameGame game, i.e. 25x15 with 5 colors. Minimum required number of connected tiles for removal is 2. Goal of the game is to clear the entire board of colored tiles.

## match-3

This game version offers a progression of levels that are completed by removing a target number of colored tiles from the board. The levels increase in difficulty as the target number of tiles and/or the number of colors increases. The board layout is 13x12 and the required minimum number of connected tiles for removal equals 3. The player earns a joker point when completing a level. When completely clearing the board of all tiles an additional joker point is awarded. 

Note that the game will not signal the end of the board until there are no more groups of connected tiles satisfying the minimum requirement (unless the target number of tiles has been reached) AND there are no more joker points left. It may be wise to retry the level (by pressing `n` or `r`, cf. [key bindings](#key_bindings)) instead of using joker points to reach the next level, as these will become more and more indispensible in later stages of the game. When retrying a level all score points gained in that level will be lost while any expended joker points will be returned to the player.

## flood

Board layout: 13x13, minimum number of connected tiles: 2. In this game version part of the board starts out empty of tiles. At each turn 6 random tiles will come dropping down. The game is lost when the board gets overflowed with tiles. Although the game can be won by clearing all tiles from the board in practice it will probably be a matter of staying "alive" as long as possible. Set your own personal goal for number of tiles cleared or total score. After every 300 tiles cleared a joker point will be awarded. Keep an eye on the joker point counter: The game can be lost with unused jokers! Note that using a joker counts as a turn and hence a new set of 6 random tiles will come dropping down.

# jokers

Joker points can be expended to use bomb wildcards. Note that tiles removed by using a joker will not add to the total score.

| joker       | effect                                   |
|:------------|:-----------------------------------------|
| row bomb    | removes all tiles in the selected row    |
| column bomb | removes all tiles in the selected column |
| bomb        | removes an area with a radius of 2       |
|             | tiles around the selected position       |

# settings

Some game configurations can be adjusted in the settings menu. The settings menu is entered by pressing `s` (cf. [key bindings](#key_bindings)). Here the settings item can be selected that is to be changed (press `h`, `l`, `left` or `right` to navigate through the items). At any point the settings menu can be exited by pressing `q` or `x`, which will bring back the unaltered board.

## seed

Set the seed for the random number generator.

Changing this setting will trigger a new board to be generated.

Corresponding flag: -s, --seed

## nr columns

Number of columns in the board layout. The minimum value is 2 and the maximum is determined by the terminal width and the tile set, i.e. (width-1)/2 for color tiles and width-1 for a representation with letters or characters.

Changing this setting will trigger a new board to be generated.

Corresponding flag: -c, --columns

## nr rows

Number of rows (or lines) in the board layout. The minimum value is 2 and the maximum is determined by the terminal height (height-3).

Changing this setting will trigger a new board to be generated.

Corresponding flag: -r, --rows

## nr colors

Number of distinct colors on the game board (minimum:2, maximum: 8).

Changing this setting will trigger a new board to be generated.

Corresponding flag: -n, --ncolors

## tile set

Sets the representation of the board in the terminal. Available values are: colors, letters and chars.

Corresponding flag: -t, --tileset

## min connected tiles

The minimum number of identical connected tiles required for removal.

Corresponding flag: -m, --minsize

## nr dropping tiles

Number of tiles that will come dropping down in the "flood" game.

Corresponding flag: -d, --ntiles

## nr empty rows

Number of empty rows on the starting board of a "flood" game. Changing this setting will trigger a new board to be generated.

Corresponding flag: -e, --emptyrows

## drop frequency

Frequency at which tiles will come dropping down in the "flood" game. The value indicates the number of turns between tile drop occurences. The default is 1, i.e. tiles will come dropping down at each turn.

Corresponding flag: -d, --dropfreq

## joker frequency

Frequency at which joker points will be awarded in the "flood" game. The number indicates the amount of tiles that have to be removed to earn a joker point.

Corresponding flag: -j, --jokerfreq

# key bindings

 | Key             | Action                     |
 |-----------------|----------------------------|
 | space,enter,tab | remove blocks              |
 | h,left          | move cursor left           |
 | l,right         | move cursor right          |
 | j,down          | move cursor down           |
 | k,up            | move cursor up             |
 | H               | move cursor to left edge   |
 | L               | move cursor to right edge  |
 | J               | move cursor to bottom edge |
 | K               | move cursor to top edge    |
 | n               | new game                   |
 | r               | replay current game        |
 | v               | change game version        |
 | s               | change setting             |
 | z               | redraw board               |
 | q               | quit game                  |
 | u               | use joker                  |
 | x               | pass turn (flood game)     |
 | i               | show game info             |
 | ?               | display key bindings       |"

