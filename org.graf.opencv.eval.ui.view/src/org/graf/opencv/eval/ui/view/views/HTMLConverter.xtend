package org.graf.opencv.eval.ui.view.views

import org.opencv.core.Mat
import org.opencv.core.MatOfByte
import org.opencv.imgcodecs.Imgcodecs
import java.util.Base64
import java.util.List
import org.grafandreas.opencv.eval.ui.handler.DisplayConfig

class HTMLConverter {
	def dispatch conv(Object arg, DisplayConfig dc) '''
	«arg»
	'''
	
	def dispatch conv(Mat arg, DisplayConfig dc) '''
		«IF (arg.width < 5 && arg.height < 5) || dc === DisplayConfig.MATRIX»
			«arg.m2h»
		«ELSE»
			<img src="data:image/gif;base64,«encode(arg)»"/>
		«ENDIF»
	'''
	
	def dispatch CharSequence conv(List<Object> arg, DisplayConfig dc) '''
		«IF arg.forall[it instanceof Mat]»
			<table><tr>«FOR m:arg.filter(Mat)»<td>«this.conv(m,dc)»</td>«ENDFOR»</tr></table>
		«ELSE»
			«arg»
		«ENDIF»
	'''
	def encode(Mat arg) {
		val matOfByte = new MatOfByte();
   		 Imgcodecs.imencode(".png", arg, matOfByte);
   		 
   		 Base64.encoder.encodeToString(matOfByte.toArray)
	}
	
	def m2h(Mat arg) '''
		<table>
			«FOR r: 0..<arg.rows»
				<tr>
				«FOR c : 0..<arg.cols»
					<td>«arg.get(r as int,c as int).toString»</td>
				«ENDFOR»
				</tr>
			«ENDFOR»
		</table>
	'''
}