package org.graf.opencv.eval.ui.view.views

import java.lang.reflect.InvocationTargetException
import java.util.LinkedHashMap
import javax.inject.Inject
import org.eclipse.core.runtime.IProgressMonitor
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.jface.action.Action
import org.eclipse.jface.action.IMenuListener
import org.eclipse.jface.action.IMenuManager
import org.eclipse.jface.action.IToolBarManager
import org.eclipse.jface.action.MenuManager
import org.eclipse.jface.action.Separator
import org.eclipse.jface.operation.IRunnableWithProgress
import org.eclipse.swt.SWT
import org.eclipse.swt.browser.Browser
import org.eclipse.swt.widgets.Composite
import org.eclipse.ui.IActionBars
import org.eclipse.ui.IPartListener
import org.eclipse.ui.ISharedImages
import org.eclipse.ui.IWorkbench
import org.eclipse.ui.IWorkbenchActionConstants
import org.eclipse.ui.IWorkbenchPart
import org.eclipse.ui.PlatformUI
import org.eclipse.ui.part.DrillDownAdapter
import org.eclipse.ui.part.ViewPart
import org.eclipse.xtext.resource.XtextResource
import org.eclipse.xtext.serializer.ISerializer
import org.eclipse.xtext.ui.editor.XtextEditor
import org.eclipse.xtext.ui.editor.model.XtextDocument
import org.eclipse.xtext.util.concurrent.IUnitOfWork
import org.eclipse.xtext.xbase.XExpression
import org.grafandreas.opencv.eval.ui.handler.XMap

/** 
 * This sample class demonstrates how to plug-in a new
 * workbench view. The view shows data obtained from the
 * model. The sample creates a dummy model on the fly,
 * but a real implementation would connect to the model
 * available either in this or another plug-in (e.g. the workspace).
 * The view is connected to the model using a content provider.
 * <p>
 * The view uses a label provider to define how model
 * objects should be presented in the view. Each
 * view can present the same model objects using
 * different labels and icons, if needed. Alternatively,
 * a single label provider can be shared between views
 * in order to ensure that objects of the same type are
 * presented in the same way everywhere.
 * <p>
 */
class OpenCVView extends ViewPart {
	/** 
	 * The ID of the view as specified by the extension.
	 */
	public static final String ID = "org.graf.opencv.eval.ui.view.views.OpenCVView"
	@Inject package IWorkbench workbench
	
//	@Inject
//	ISerializer serializer;
	
	Browser viewer
	DrillDownAdapter drillDownAdapter
	Action action1
	Action action2
	Action doubleClickAction

	override void createPartControl(Composite parent) {
		viewer = new Browser(parent, SWT::NONE)
		viewer.setText("<h1> Content </h1>")
		// Create the help context id for the viewer's control
		// workbench.getHelpSystem().setHelp(viewer.getControl(), "org.graf.opencv.eval.ui.view.viewer");
		// getSite().setSelectionProvider(viewer);
		makeActions()
		hookContextMenu()
		hookDoubleClickAction()
		// contributeToActionBars();
		getSite().getPage().addPartListener(new IPartListener() {
			override void partActivated(IWorkbenchPart part) {
				update(part)
			}

			override void partBroughtToTop(IWorkbenchPart part) { // TODO Auto-generated method stub
			}

			override void partClosed(IWorkbenchPart part) { // TODO Auto-generated method stub
			}

			override void partDeactivated(IWorkbenchPart part) { // TODO Auto-generated method stub
			}

			override void partOpened(IWorkbenchPart part) { // TODO Auto-generated method stub
			}
		})
	}

	def private void hookContextMenu() {
		var MenuManager menuMgr = new MenuManager("#PopupMenu")
		menuMgr.setRemoveAllWhenShown(true)
		menuMgr.addMenuListener(([IMenuManager manager|OpenCVView.this.fillContextMenu(manager)] as IMenuListener)) // Menu menu = menuMgr.createContextMenu(viewer.getControl());
		// viewer.getControl().setMenu(menu);
		// getSite().registerContextMenu(menuMgr, viewer);
	}

	def private void contributeToActionBars() {
		var IActionBars bars = getViewSite().getActionBars()
		fillLocalPullDown(bars.getMenuManager())
		fillLocalToolBar(bars.getToolBarManager())
	}

	def private void fillLocalPullDown(IMenuManager manager) {
		manager.add(action1)
		manager.add(new Separator())
		manager.add(action2)
	}

	def private void fillContextMenu(IMenuManager manager) {
		manager.add(action1)
		manager.add(action2)
		manager.add(new Separator())
		drillDownAdapter.addNavigationActions(manager)
		// Other plug-ins can contribute there actions here
		manager.add(new Separator(IWorkbenchActionConstants::MB_ADDITIONS))
	}

	def private void fillLocalToolBar(IToolBarManager manager) {
		manager.add(action1)
		manager.add(action2)
		manager.add(new Separator())
		drillDownAdapter.addNavigationActions(manager)
	}

	def private void makeActions() {
		action1 = new Action() {
			override void run() {
				showMessage("Action 1 executed")
			}
		}
		action1.setText("Action 1")
		action1.setToolTipText("Action 1 tooltip")
		action1.setImageDescriptor(
			PlatformUI::getWorkbench().getSharedImages().getImageDescriptor(ISharedImages::IMG_OBJS_INFO_TSK))
		action2 = new Action() {
			override void run() {
				showMessage("Action 2 executed")
			}
		}
		action2.setText("Action 2")
		action2.setToolTipText("Action 2 tooltip")
		action2.setImageDescriptor(workbench.getSharedImages().getImageDescriptor(ISharedImages::IMG_OBJS_INFO_TSK))
		doubleClickAction = new Action() {
			override void run() { // IStructuredSelection selection = viewer.getStructuredSelection();
				// Object obj = selection.getFirstElement();
				// showMessage("Double-click detected on "+obj.toString());
			}
		}
	}

	def private void hookDoubleClickAction() { // viewer.addDoubleClickListener(new IDoubleClickListener() {
		// public void doubleClick(DoubleClickEvent event) {
		// doubleClickAction.run();
		// }
		// });
	}

	def private void showMessage(String message) { // MessageDialog.openInformation(
		// viewer.getControl().getShell(),
		// "OpenCV View",
		// message);
	}

	override void setFocus() { // viewer.getControl().setFocus();
	}

	def package void update(IWorkbenchPart activeEditor) {
		if (activeEditor !== null && activeEditor instanceof XtextEditor) {
			val XtextEditor editor = (activeEditor as XtextEditor)
			// IProject project = ((IFileEditorInput)editor.getEditorInput()).getFile().getProject();
			val Holder<String> ref = new Holder<String>()
			try {
				workbench.getProgressService().run(true, true, ([ IProgressMonitor monitor |
					var XtextDocument doc = (editor.getDocument() as XtextDocument)
					var String result = doc.readOnly(([ XtextResource r |
						val conv = new HTMLConverter
						val adapter = adapt(r) as LinkedHashMap<XExpression,Object>
						return '''
						
						<table border="1">
						«FOR e : adapter.entrySet()»
							<tr><td>«IF e.value !== null»«conv.conv(e.value)»«ELSE»«ENDIF»</td><td></td></tr>
						«ENDFOR»
						</table>
						'''
					] as IUnitOfWork<String, XtextResource>))
					ref.set(result)
				] as IRunnableWithProgress))
			} catch (InvocationTargetException e) {
				e.printStackTrace()
			} catch (InterruptedException e) {
				e.printStackTrace()
			}

			viewer.setText(ref.get())
		}
	}

	static  class Holder<T> {
		T t

		new() {
		}

		def T get() {
			return t
		}

		def void set(T t) {
			this.t = t
		}
	}

	def XMap adapt(Resource r) {
		var oadapter = r.eAdapters().filter(XMap).head();
		var XMap adapter = if(oadapter !== null) oadapter else
			{
				var XMap res = new XMap()
				r.eAdapters().add(res)
				res
			}
	
		return adapter
	}
}
