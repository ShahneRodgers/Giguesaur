/*
    File: ExtraCode.c
    Author: Ashley Manson

    Some code that might be needed.
 */

/*
 OpenGLView.m: - (void) render

 // Projection Matrix
 float aspectFrustum = 4.0f * BOARD_HIEGHT / BOARD_WIDTH;
 float aspect = BOARD_HIEGHT / BOARD_WIDTH;
 GLKMatrix4 projection = GLKMatrix4MakeFrustum(-2, 2, -aspectFrustum/2, aspectFrustum/2, 1, 1000);
 GLKMatrix4 projection = GLKMatrix4MakePerspective(degToRad(90), aspect, 0.01f, 1000.0f);

 GLKMatrix4 identity = GLKMatrix4Identity;
 GLKMatrix4 lookAt = GLKMatrix4MakeLookAt(0, 0, 0, self.frame.size.width/2, self.frame.size.height/2, 1, 0, 1, 0);
 GLKMatrix4 plusTranslate = GLKMatrix4MakeTranslation(self.frame.size.width/2, self.frame.size.height/2, 0.0);
 GLKMatrix4 negTranslate = GLKMatrix4MakeTranslation(-self.frame.size.width/2, -self.frame.size.height/2, 0.0);
 GLKMatrix4 rotateY = GLKMatrix4MakeYRotation(degToRad(-90.0f));
 GLKMatrix4 rotateX = GLKMatrix4MakeXRotation(degToRad(45.0f));

 GLKMatrix4 result1 = GLKMatrix4Multiply(identity, lookAt);
 GLKMatrix4 result2 = GLKMatrix4Multiply(result1, plusTranslate);
 result1 = GLKMatrix4Multiply(result2, rotateY);
 result2 = GLKMatrix4Multiply(result1, rotateX);
 GLKMatrix4 modelView = GLKMatrix4Multiply(result2, negTranslate);
 glUniformMatrix4fv(_modelViewUniform, 1, 0, modelView.m);

 */
