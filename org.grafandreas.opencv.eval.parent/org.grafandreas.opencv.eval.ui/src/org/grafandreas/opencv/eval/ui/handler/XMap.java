package org.grafandreas.opencv.eval.ui.handler;

import java.util.LinkedHashMap;

import org.eclipse.emf.common.notify.Adapter;
import org.eclipse.emf.common.notify.Notification;
import org.eclipse.emf.common.notify.Notifier;
import org.eclipse.xtext.xbase.XExpression;

public class XMap extends LinkedHashMap<XExpression, Object> implements Adapter {

		/**
	 * 
	 */
	private static final long serialVersionUID = 1L;

		@Override
		public void notifyChanged(Notification notification) {
			// TODO Auto-generated method stub
			
		}

		@Override
		public Notifier getTarget() {
			// TODO Auto-generated method stub
			return null;
		}

		@Override
		public void setTarget(Notifier newTarget) {
			// TODO Auto-generated method stub
			
		}

		@Override
		public boolean isAdapterForType(Object type) {
			// TODO Auto-generated method stub
			return false;
		}
		
	}