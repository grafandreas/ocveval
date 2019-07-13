package org.grafandreas.opencv.eval.ui.handler;
import java.lang.reflect.InvocationTargetException;
import java.net.URL;
import java.net.URLClassLoader;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.IHandler;
import org.eclipse.core.resources.IFolder;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IWorkspaceRoot;
import org.eclipse.core.runtime.IPath;
import org.eclipse.core.runtime.IProgressMonitor;
import org.eclipse.emf.common.notify.Adapter;
import org.eclipse.emf.common.notify.Notification;
import org.eclipse.emf.common.notify.Notifier;
import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.jdt.core.IClasspathEntry;
import org.eclipse.jdt.core.IJavaProject;
import org.eclipse.jdt.core.JavaCore;
import org.eclipse.jface.operation.IRunnableWithProgress;
import org.eclipse.swt.widgets.Display;
import org.eclipse.ui.IEditorPart;
import org.eclipse.ui.IFileEditorInput;
import org.eclipse.ui.IWorkbench;
import org.eclipse.ui.handlers.HandlerUtil;


import org.eclipse.xtext.naming.IQualifiedNameConverter;
import org.eclipse.xtext.resource.IResourceDescriptions;
import org.eclipse.xtext.resource.XtextResource;
import org.eclipse.xtext.resource.XtextResourceSet;
import org.eclipse.xtext.resource.impl.EagerResourceSetBasedResourceDescriptions;
import org.eclipse.xtext.serializer.ISerializer;
import org.eclipse.xtext.ui.editor.XtextEditor;
import org.eclipse.xtext.ui.editor.model.XtextDocument;
import org.eclipse.xtext.ui.resource.IResourceSetProvider;
import org.eclipse.xtext.ui.util.JavaProjectFactory;
import org.eclipse.xtext.util.CancelIndicator;
import org.eclipse.xtext.util.concurrent.IUnitOfWork;
import org.eclipse.xtext.xbase.XExpression;
import org.eclipse.xtext.xbase.XMemberFeatureCall;
import org.eclipse.xtext.xbase.interpreter.IEvaluationContext;
import org.eclipse.xtext.xbase.interpreter.IEvaluationResult;
import org.eclipse.xtext.xbase.interpreter.impl.DefaultEvaluationContext;
import org.eclipse.xtext.xbase.interpreter.impl.XbaseInterpreter;
import org.eclipse.xtext.xbase.lib.IterableExtensions;
import org.eclipse.xtext.xtype.XImportDeclaration;
import org.grafandreas.opencv.eval.interpreter.OpenCVInterpreter;
import org.grafandreas.opencv.eval.oCVEval.Model;
import org.grafandreas.opencv.eval.oCVEval.XMethodDeclaration;

import com.google.common.collect.ImmutableMap;
import com.google.common.collect.Sets;
import com.google.inject.Inject;
import com.google.inject.Injector;
import com.google.inject.Provider;

@SuppressWarnings("restriction")
public class ModelQueryInterpreterHandler extends AbstractHandler implements IHandler {

	@Inject
	IResourceDescriptions resourceDescriptions;

	@Inject
	Provider<ResourceSet> resourceSetProvider;
	@Inject
	IResourceSetProvider resourceSetByProjectProvider;

	@Inject
	private Provider<XbaseInterpreter> interpreterProvider;

	@Inject
	JavaProjectFactory javaProjectFactory;

	@Inject
	IQualifiedNameConverter qualifiedNameConverter;

	@Inject
	ISerializer serializer;

	@Inject
	Injector injector;

	@Inject
	IWorkbench workbench;
	
	
	@Inject
	IResourceSetProvider rsp;
	
	Cloner cloner = new Cloner();
	
	Map<String,Integer> callMap =  ImmutableMap.of( "org.opencv.imgproc.Imgproc.Canny" , 1,
			"org.opencv.core.Core.split",1,
			"org.opencv.imgproc.Imgproc.cvtColor",1,
			"org.opencv.core.Core.normalize",1
			
			);

	@Override
	public Object execute(ExecutionEvent event) {

//		final IWorkbenchPart view = HandlerUtil.getActivePart(event);
		IEditorPart activeEditor = HandlerUtil.getActiveEditor(event);
//		 if (view instanceof ModelQueryLanguageView) {
//			final ModelQueryLanguageView mqlv = (ModelQueryLanguageView) view;
//			final Holder<String> ref = new Holder<String>();
//			try {
//				workbench.getProgressService().run(true, true, new IRunnableWithProgress() {
//
//					@Override
//					public void run(final IProgressMonitor monitor) throws InvocationTargetException, InterruptedException {
//						XtextDocument doc = ((ModelQueryLanguageView) view).getEmbeddedEditor().getDocument();
//						String result = doc.readOnly(new IUnitOfWork<String, XtextResource>() {
//							@Override
//							public String exec(XtextResource r) throws Exception {
//								Model m = (Model) r.getContents().get(0);
//								return interpret(m, monitor);
//							}
//						});
//						ref.set(result);
//					}
//				});
//				mqlv.getEmbeddedEditorResult().getDocument().set(ref.get());
//			} catch (InvocationTargetException e) {
//				e.printStackTrace();
//			} catch (InterruptedException e) {
//				e.printStackTrace();
//			}
//
//		} else 
		if (activeEditor != null && activeEditor instanceof XtextEditor) {
			final XtextEditor editor = (XtextEditor) activeEditor;
			IProject project = ((IFileEditorInput)editor.getEditorInput()).getFile().getProject();
			final Holder<String> ref = new Holder<String>();
			try {
				workbench.getProgressService().run(true, true, new IRunnableWithProgress() {

					@Override
					public void run(final IProgressMonitor monitor) throws InvocationTargetException, InterruptedException {
						XtextDocument doc = (XtextDocument) editor.getDocument();
						String result = doc.readOnly(new IUnitOfWork<String, XtextResource>() {
							@Override
							public String exec(XtextResource r) throws Exception {
								Model m = (Model) r.getContents().get(0);
								return interpret(project, m, monitor);
							}
						});
						ref.set(result);
					}
				});
			} catch (InvocationTargetException e) {
				e.printStackTrace();
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
			System.out.println(ref.get());
//			ModelQueryLanguageDialog dialog = new ModelQueryLanguageDialog(Display.getCurrent().getActiveShell(), ref.get(), project);
//			injector.injectMembers(dialog);
//			dialog.open();

		} 
		return null;
	}
	
	protected XbaseInterpreter getConfiguredInterpreter(XtextResource resource) {
		XbaseInterpreter interpreter2 = interpreterProvider.get();
		ResourceSet set = resource.getResourceSet();
		ClassLoader cl = getClass().getClassLoader();
		if (set instanceof XtextResourceSet) {
			// if this does not fit your needs have a look at XcoreJavaProjectProvider
			Object context = ((XtextResourceSet) set).getClasspathURIContext();
			if (context instanceof IJavaProject) {
				try {
					final IJavaProject jp = (IJavaProject) context;
					// String[] runtimeClassPath =
					// JavaRuntime.computeDefaultRuntimeClassPath(jp);
					// URL[] urls = new URL[runtimeClassPath.length];
					// for (int i = 0; i < urls.length; i++) {
					// urls[i] = new URL(runtimeClassPath[i]);
					// }
					// cl = new URLClassLoader(urls);
					IClasspathEntry[] classpath = jp.getResolvedClasspath(true);
					final IWorkspaceRoot root = jp.getProject().getWorkspace().getRoot();
					Set<URL> urls = Sets.<URL>newHashSet();
					for (int i = 0; i < classpath.length; i++) {
						final IClasspathEntry entry = classpath[i];
						if (entry.getEntryKind() == IClasspathEntry.CPE_SOURCE) {
							IPath outputLocation = entry.getOutputLocation();
							if (outputLocation == null) {
								outputLocation = jp.getOutputLocation();
							}
							IFolder folder = root.getFolder(outputLocation);
							if (folder.exists()) {
								urls.add(new URL(folder.getRawLocationURI().toASCIIString() + "/"));
							}
						} else if (entry.getEntryKind() == IClasspathEntry.CPE_PROJECT) {
							IPath outputLocation = entry.getOutputLocation();
							if (outputLocation == null) {
								IProject project = (IProject) jp.getProject().getWorkspace().getRoot()
										.getContainerForLocation(entry.getPath());
								IJavaProject javaProject = JavaCore.create(project);
								outputLocation = javaProject.getOutputLocation();
							}
							IFolder folder = root.getFolder(outputLocation);
							if (folder.exists()) {
								urls.add(new URL(folder.getRawLocationURI().toASCIIString() + "/"));
							}
						} else {
							urls.add(entry.getPath().toFile().toURI().toURL());
						}
					}
					System.out.println(urls);
					cl = new URLClassLoader(urls.toArray(new URL[urls.size()]), cl);
				} catch (Exception e) {
					e.printStackTrace();
				}
			}
		}
		interpreter2.setClassLoader(cl);
		return interpreter2;
	}
	
	public XMap adapt(Resource r ) {
		Optional<XMap> oadapter = r.eAdapters().stream().filter((x) -> x instanceof XMap).map(XMap.class::cast).findFirst();
		XMap adapter = oadapter.orElseGet(() -> {XMap res = new XMap(); r.eAdapters().add(res); return res;});
		return adapter;
	}
	
	private String interpret(final IProject project, final Model m, final IProgressMonitor monitor) {
		
		callMap.put("org.opencv.imgproc.Imgproc.HoughLinesP",1);
		IEvaluationContext context = new DefaultEvaluationContext();
		XbaseInterpreter configuredInterpreter = getConfiguredInterpreter((XtextResource)m.eResource());
		
		String postfix = m.eResource().getURI().trimFileExtension().lastSegment();
		XMap adapter = adapt(m.eResource());
		adapter.clear();
		
		final List<String> data = new ArrayList<String>();
//		context.newValue(qualifiedNameConverter.toQualifiedName(IModelQueryConstants.INFERRED_CLASS_NAME + postfix + "." + IModelQueryConstants.INDEX), resourceDescriptions);
//		context.newValue(qualifiedNameConverter.toQualifiedName(IModelQueryConstants.INFERRED_CLASS_NAME + postfix+ "." + IModelQueryConstants.RESOURCESET), resourceSetProvider.get());
//		context.newValue(qualifiedNameConverter.toQualifiedName(IModelQueryConstants.INFERRED_CLASS_NAME + postfix+ "." + IModelQueryConstants.PROJECT), project);
//		context.newValue(qualifiedNameConverter.toQualifiedName(IModelQueryConstants.INFERRED_CLASS_NAME + postfix + "." + IModelQueryConstants.INJECTOR), injector);
		if (m.getImportSection() != null) {
			for (XImportDeclaration i : m.getImportSection().getImportDeclarations()) {
				data.add(serializer.serialize(i).trim());
			}
		}
		for (XMethodDeclaration d : m.getMethods()) {
			data.add(serializer.serialize(d).trim());
		}
		monitor.beginTask("Interpreting", m.getBody().getExpressions().size());
		for (XExpression x : m.getBody().getExpressions()) {
			if (monitor.isCanceled()) {
				System.out.println("mumu");
				monitor.done();
				return IterableExtensions.join(data, "\n");
			}
			IEvaluationResult result = configuredInterpreter.evaluate(x, context, CancelIndicator.NullImpl);
			System.out.println("!!!"+result +" : "+result.getResult());
			
			data.add(serializer.serialize(x).trim());
			if (result.getException() != null) {
				data.add("// Exception: " + result.getException().getMessage());
				result.getException().printStackTrace();
				return IterableExtensions.join(data, "\n");
			} else {
				
				adapter.put(x, new TraceData(serializer.serialize(x).trim(), cloner.clone(result.getResult()), null));
				if(x instanceof XMemberFeatureCall) {
					if(callMap.containsKey(((XMemberFeatureCall) x).getFeature().getQualifiedName())) {
						Integer idx = callMap.get(((XMemberFeatureCall) x).getFeature().getQualifiedName());
						if(((XMemberFeatureCall) x).getFeature().getQualifiedName().equals("org.opencv.imgproc.Imgproc.HoughLinesP")) {
							adapter.put(x, new TraceData(serializer.serialize(x).trim(),cloner.clone(((OpenCVInterpreter) configuredInterpreter).lastArgumentValues.get(idx)), DisplayConfig.MATRIX));
						}
						else
							adapter.put(x, new TraceData(serializer.serialize(x).trim(),cloner.clone(((OpenCVInterpreter) configuredInterpreter).lastArgumentValues.get(idx)), null));
					}
				}
				
				if (result.getResult() == null) {
					data.add("// null");
				} else {
					data.add("//" + result.getResult().getClass().getSimpleName() + ": " + result.getResult().toString());
				}
			}
			monitor.worked(1);

		}
		monitor.done();
		return IterableExtensions.join(data, "\n");
	}

	@Override
	public boolean isEnabled() {
		return true;
	}

	static class Holder<T> {
		private T t;

		public Holder() {
		}

		public T get() {
			return t;
		}

		public void set(T t) {
			this.t = t;
		}
	}
	

}