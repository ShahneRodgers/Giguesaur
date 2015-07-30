/*
 File: ExtraCode.m
 Author: Ashley Manson
 
 Extra code from the graphics component
 */
/*
 
 // Move a piece if it is in range to snap to another piece
 - (void) checkThenSnapPiece: (int) pieceID {

 CGPoint newPoints;
 int upID = pieces[pieceID].neighbourPiece.up_piece;
 int downID = pieces[pieceID].neighbourPiece.down_piece;
 int leftID = pieces[pieceID].neighbourPiece.left_piece;
 int rightID = pieces[pieceID].neighbourPiece.right_piece;

 if (upID >= 0 &&
 [simpleMath shouldPieceSnap:pieces[pieceID]
 withOtherPiece:pieces[upID]
 whichSide:P_UP
 distanceBeforeSnap:DISTANCE_BEFORE_SNAP]) {

 newPoints = [simpleMath newCoordinates:pieces[upID] whichSide:P_UP];
 pieces[pieceID].x_location = newPoints.x;
 pieces[pieceID].y_location = newPoints.y;
 pieces[pieceID].rotation = pieces[upID].rotation;

 DEBUG_PRINT_2("checkThenSnapPiece :: Moved piece %i to (%.2f, %.2f)\n",
 pieceID, newPoints.x, newPoints.y);
 }

 if (downID >= 0 &&
 [simpleMath shouldPieceSnap:pieces[pieceID]
 withOtherPiece:pieces[downID]
 whichSide:P_DOWN
 distanceBeforeSnap:DISTANCE_BEFORE_SNAP]) {

 newPoints = [simpleMath newCoordinates:pieces[downID] whichSide:P_DOWN];
 pieces[pieceID].x_location = newPoints.x;
 pieces[pieceID].y_location = newPoints.y;
 pieces[pieceID].rotation = pieces[downID].rotation;

 DEBUG_PRINT_2("checkThenSnapPiece :: Moved piece %i to (%.2f, %.2f)\n",
 pieceID, newPoints.x, newPoints.y);
 }

 if (leftID >= 0 &&
 [simpleMath shouldPieceSnap:pieces[pieceID]
 withOtherPiece:pieces[leftID]
 whichSide:P_LEFT
 distanceBeforeSnap:DISTANCE_BEFORE_SNAP]) {

 newPoints = [simpleMath newCoordinates:pieces[leftID] whichSide:P_LEFT];
 pieces[pieceID].x_location = newPoints.x;
 pieces[pieceID].y_location = newPoints.y;
 pieces[pieceID].rotation = pieces[leftID].rotation;

 DEBUG_PRINT_2("checkThenSnapPiece :: Moved piece %i to (%.2f, %.2f)\n",
 pieceID, newPoints.x, newPoints.y);

 }

 if (rightID >= 0 &&
 [simpleMath shouldPieceSnap:pieces[pieceID]
 withOtherPiece:pieces[rightID]
 whichSide:P_RIGHT
 distanceBeforeSnap:DISTANCE_BEFORE_SNAP]) {

 newPoints = [simpleMath newCoordinates:pieces[rightID] whichSide: P_RIGHT];
 pieces[pieceID].x_location = newPoints.x;
 pieces[pieceID].y_location = newPoints.y;
 pieces[pieceID].rotation = pieces[rightID].rotation;

 DEBUG_PRINT_2("checkThenSnapPiece :: Moved piece %i to (%.2f, %.2f)\n",
 pieceID, newPoints.x, newPoints.y);
 }
 }

 // Check if a piece joined its neighbours then closes their edges
 - (void) checkThenCloseEdge: (int) pieceID {

 int upID = pieces[pieceID].neighbourPiece.up_piece;
 int downID = pieces[pieceID].neighbourPiece.down_piece;
 int leftID = pieces[pieceID].neighbourPiece.left_piece;
 int rightID = pieces[pieceID].neighbourPiece.right_piece;

 if (upID >= 0 &&
 [simpleMath didPieceConnect:pieces[pieceID]
 withOtherPiece:pieces[upID]
 whichSide:P_UP]) {

 pieces[pieceID].openEdge.up_open = isClosed;
 pieces[upID].openEdge.down_open = isClosed;

 DEBUG_PRINT_2("checkThenCloseEdge :: Piece %i joined piece %i\n",
 pieceID, upID);
 }

 if (downID >= 0 &&
 [simpleMath didPieceConnect:pieces[pieceID]
 withOtherPiece:pieces[downID]
 whichSide:P_DOWN]) {

 pieces[pieceID].openEdge.down_open = isClosed;
 pieces[downID].openEdge.up_open = isClosed;

 DEBUG_PRINT_2("checkThenCloseEdge :: Piece %i joined piece %i\n",
 pieceID, downID);
 }

 if (leftID >= 0 &&
 [simpleMath didPieceConnect:pieces[pieceID]
 withOtherPiece:pieces[leftID]
 whichSide:P_LEFT]) {

 pieces[pieceID].openEdge.left_open = isClosed;
 pieces[leftID].openEdge.right_open = isClosed;

 DEBUG_PRINT_2("checkThenCloseEdge :: Piece %i joined piece %i\n",
 pieceID, leftID);
 }

 if (rightID >= 0 &&
 [simpleMath didPieceConnect:pieces[pieceID]
 withOtherPiece:pieces[rightID]
 whichSide:P_RIGHT]) {

 pieces[pieceID].openEdge.right_open = isClosed;
 pieces[rightID].openEdge.left_open = isClosed;

 DEBUG_PRINT_2("checkThenCloseEdge :: Piece %i joined piece %i\n",
 pieceID, rightID);
 }
 }

 // Open closed edges of pickedup piece and neighbouring edges
 - (void) openClosedEdges: (int) pieceID {

 int upID = pieces[pieceID].neighbourPiece.up_piece;
 int downID = pieces[pieceID].neighbourPiece.down_piece;
 int leftID = pieces[pieceID].neighbourPiece.left_piece;
 int rightID = pieces[pieceID].neighbourPiece.right_piece;

 if (upID >= 0) {
 pieces[pieceID].openEdge.up_open = isOpen;
 pieces[upID].openEdge.down_open = isOpen;

 DEBUG_PRINT_2("openClosedEdges :: Piece %i up_open = isOpen\n"
 "                   Piece %i down_open = isOpen\n",
 pieceID, upID);
 }
 if (downID >= 0) {
 pieces[pieceID].openEdge.down_open = isOpen;
 pieces[downID].openEdge.up_open = isOpen;

 DEBUG_PRINT_2("openClosedEdges :: Piece %i down_open = isOpen\n"
 "                   Piece %i up_open = isOpen\n",
 pieceID, downID);
 }
 if (leftID >= 0) {
 pieces[pieceID].openEdge.left_open = isOpen;
 pieces[leftID].openEdge.right_open = isOpen;

 DEBUG_PRINT_2("openClosedEdges :: Piece %i left_open = isOpen\n"
 "                   Piece %i right_open = isOpen\n",
 pieceID, leftID);
 }
 if (rightID >= 0) {
 pieces[pieceID].openEdge.right_open = isOpen;
 pieces[rightID].openEdge.left_open = isOpen;

 DEBUG_PRINT_2("openClosedEdges :: Piece %i right_open = isOpen\n"
 "                   Piece %i left_open = isOpen\n",
 pieceID, rightID);
 }
 }



 */
