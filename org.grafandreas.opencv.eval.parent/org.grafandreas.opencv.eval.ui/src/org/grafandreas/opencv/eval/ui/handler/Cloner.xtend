package org.grafandreas.opencv.eval.ui.handler

import com.google.common.collect.Lists
import java.util.List
import org.opencv.core.Mat

class Cloner {
	def  Object clone(Object o) {
		if( o !== null )
			o.doclone()
		else
			null
	}
	
	def dispatch Object doclone(Cloneable o) {
			o
	
	}
	
	def dispatch doclone(Mat o) {
		o.clone
	}
	
	def dispatch Object doclone(List o) {
		val r = Lists.newArrayList
		
		r += o.map[this.clone(it)]
		
		r
	}
	
}