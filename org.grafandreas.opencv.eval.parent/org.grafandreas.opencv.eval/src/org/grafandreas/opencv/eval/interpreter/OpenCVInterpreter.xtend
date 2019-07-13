package org.grafandreas.opencv.eval.interpreter

import com.google.common.collect.Lists
import com.google.inject.Inject
import java.util.List
import org.eclipse.xtext.common.types.JvmOperation
import org.eclipse.xtext.common.types.JvmPrimitiveType
import org.eclipse.xtext.naming.QualifiedName
import org.eclipse.xtext.util.CancelIndicator
import org.eclipse.xtext.xbase.XVariableDeclaration
import org.eclipse.xtext.xbase.interpreter.IEvaluationContext
import org.eclipse.xtext.xbase.interpreter.impl.XbaseInterpreter
import org.eclipse.xtext.xbase.typesystem.util.CommonTypeComputationServices
import org.grafandreas.opencv.bundle.activator.Activator
import org.opencv.core.CvType
import org.opencv.core.Mat
import java.util.ArrayList

//import org.opencv.Activator


class OpenCVInterpreter extends XbaseInterpreter { 
	
		@Inject
	private CommonTypeComputationServices services;
	
	public List<Object> lastArgumentValues
	
	new() {
		super()
		println("Constructor")
		 System.loadLibrary("opencv_java410");
//		val mat = Mat.eye(3, 3, CvType::CV_8UC1)		

		Activator.ll()
		Activator.t()
		
		val mat = Mat.eye(3, 3, CvType::CV_8UC1)
		println(mat)
	}
	
	override protected Object invokeOperation(JvmOperation operation, Object receiver, List<Object> argumentValues) {
			val method = javaReflectAccess.getMethod(operation);
			
			println("LoadLib")
//				Activator.loadLib()
			System.loadLibrary("opencv_java410")
			println(this.class.classLoader)
			println(operation)
			println(method.declaringClass.classLoader)
//			val sys = method.declaringClass.classLoader.loadClass("java.lang.System")
//			println(sys.classLoader)
//			println(sys.class.classLoader)
//			val m = sys.getMethod("loadLibrary",String)
//			m.invoke(null, "opencv_java410")
		this.lastArgumentValues = Lists.newArrayList(argumentValues)
		return super.invokeOperation(operation,receiver,argumentValues)
	}
	
	// We want to override this, since the original function does not return the initial value
	//
		override Object _doEvaluate(XVariableDeclaration variableDecl, IEvaluationContext context, CancelIndicator indicator) {
		var Object initialValue = null;
		if (variableDecl.getRight()!=null) {
			initialValue = internalEvaluate(variableDecl.getRight(), context, indicator);
		} else {
			if (services.getPrimitives().isPrimitive(variableDecl.getType())) {
				val primitiveKind = services.getPrimitives().primitiveKind( variableDecl.getType().getType() as JvmPrimitiveType);
				switch(primitiveKind) {
					case Boolean:
						initialValue = Boolean.FALSE
					case Char:
						initialValue = Character.valueOf(0 as char)
					case Double:
						initialValue = Double.valueOf(0d)
					case Byte:
						initialValue = Byte.valueOf(0 as byte)
					case Float:
						initialValue = Float.valueOf(0f)
					case Int:
						initialValue = Integer.valueOf(0)
					case Long:
						initialValue = Long.valueOf(0L)
					case Short:
						initialValue = Short.valueOf(0 as short)
					case Void:
						throw new IllegalStateException("Void is not a valid variable type.")
					default:
						throw new IllegalStateException("Unknown primitive type " + primitiveKind)
				}
			}
		}
		context.newValue(QualifiedName.create(variableDecl.getName()), initialValue);
		return initialValue;
	}
	
	
	 
}