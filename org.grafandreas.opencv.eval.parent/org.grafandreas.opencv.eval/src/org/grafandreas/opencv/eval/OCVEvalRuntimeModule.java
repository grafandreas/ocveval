/*
 * generated by Xtext 2.18.0.M3
 */
package org.grafandreas.opencv.eval;

import org.eclipse.xtext.xbase.interpreter.impl.XbaseInterpreter;
import org.grafandreas.opencv.eval.interpreter.OpenCVInterpreter;

/**
 * Use this class to register components to be used at runtime / without the Equinox extension registry.
 */
@SuppressWarnings("restriction")
public
class OCVEvalRuntimeModule extends AbstractOCVEvalRuntimeModule {
	public Class<? extends XbaseInterpreter> bindXbaseInterpreter() {
		return  OpenCVInterpreter.class;
	} 

}