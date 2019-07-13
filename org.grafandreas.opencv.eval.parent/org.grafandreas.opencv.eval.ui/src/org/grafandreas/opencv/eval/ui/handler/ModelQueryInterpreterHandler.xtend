package org.grafandreas.opencv.eval.ui.handler

import java.lang.reflect.InvocationTargetException
import java.net.URL
import java.net.URLClassLoader
import java.util.ArrayList
import java.util.LinkedHashMap
import java.util.LinkedHashSet
import java.util.List
import java.util.Map
import java.util.Optional
import java.util.Set
import org.eclipse.core.commands.AbstractHandler
import org.eclipse.core.commands.ExecutionEvent
import org.eclipse.core.commands.IHandler
import org.eclipse.core.resources.IFolder
import org.eclipse.core.resources.IProject
import org.eclipse.core.resources.IWorkspaceRoot
import org.eclipse.core.runtime.IPath
import org.eclipse.core.runtime.IProgressMonitor
import org.eclipse.emf.common.notify.Adapter
import org.eclipse.emf.common.notify.Notification
import org.eclipse.emf.common.notify.Notifier
import org.eclipse.emf.common.util.EList
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.jdt.core.IClasspathEntry
import org.eclipse.jdt.core.IJavaProject
import org.eclipse.jdt.core.JavaCore
import org.eclipse.jface.operation.IRunnableWithProgress
import org.eclipse.swt.widgets.Display
import org.eclipse.ui.IEditorPart
import org.eclipse.ui.IFileEditorInput
import org.eclipse.ui.IWorkbench
import org.eclipse.ui.handlers.HandlerUtil
import org.eclipse.xtext.naming.IQualifiedNameConverter
import org.eclipse.xtext.resource.IResourceDescriptions
import org.eclipse.xtext.resource.XtextResource
import org.eclipse.xtext.resource.XtextResourceSet
import org.eclipse.xtext.resource.impl.EagerResourceSetBasedResourceDescriptions
import org.eclipse.xtext.serializer.ISerializer
import org.eclipse.xtext.ui.editor.XtextEditor
import org.eclipse.xtext.ui.editor.model.XtextDocument
import org.eclipse.xtext.ui.resource.IResourceSetProvider
import org.eclipse.xtext.ui.util.JavaProjectFactory
import org.eclipse.xtext.util.CancelIndicator
import org.eclipse.xtext.util.concurrent.IUnitOfWork
import org.eclipse.xtext.xbase.XExpression
import org.eclipse.xtext.xbase.XMemberFeatureCall
import org.eclipse.xtext.xbase.interpreter.IEvaluationContext
import org.eclipse.xtext.xbase.interpreter.IEvaluationResult
import org.eclipse.xtext.xbase.interpreter.impl.DefaultEvaluationContext
import org.eclipse.xtext.xbase.interpreter.impl.XbaseInterpreter
import org.eclipse.xtext.xbase.lib.IterableExtensions
import org.eclipse.xtext.xtype.XImportDeclaration
import org.grafandreas.opencv.eval.interpreter.OpenCVInterpreter
import org.grafandreas.opencv.eval.oCVEval.Model
import org.grafandreas.opencv.eval.oCVEval.XMethodDeclaration
import com.google.common.collect.ImmutableMap
import com.google.common.collect.Sets
import com.google.inject.Inject
import com.google.inject.Injector
import com.google.inject.Provider

@SuppressWarnings("restriction") class ModelQueryInterpreterHandler extends AbstractHandler implements IHandler {
	@Inject package IResourceDescriptions resourceDescriptions
	@Inject package Provider<ResourceSet> resourceSetProvider
	@Inject package IResourceSetProvider resourceSetByProjectProvider
	@Inject Provider<XbaseInterpreter> interpreterProvider
	@Inject package JavaProjectFactory javaProjectFactory
	@Inject package IQualifiedNameConverter qualifiedNameConverter
	@Inject package ISerializer serializer
	@Inject package Injector injector
	@Inject package IWorkbench workbench
	@Inject package IResourceSetProvider rsp
	package Cloner cloner = new Cloner()
	val  callMap = #{"org.opencv.imgproc.Imgproc.Canny"-> 1,
		"org.opencv.core.Core.split"-> 1, "org.opencv.imgproc.Imgproc.cvtColor"-> 1, "org.opencv.core.Core.normalize"-> 1,
		"org.opencv.imgproc.Imgproc.HoughLinesP" -> 1}

	override Object execute(ExecutionEvent event) {
		// final IWorkbenchPart view = HandlerUtil.getActivePart(event);
		var IEditorPart activeEditor = HandlerUtil::getActiveEditor(event)
		// if (view instanceof ModelQueryLanguageView) {
		// final ModelQueryLanguageView mqlv = (ModelQueryLanguageView) view;
		// final Holder<String> ref = new Holder<String>();
		// try {
		// workbench.getProgressService().run(true, true, new IRunnableWithProgress() {
		//
		// @Override
		// public void run(final IProgressMonitor monitor) throws InvocationTargetException, InterruptedException {
		// XtextDocument doc = ((ModelQueryLanguageView) view).getEmbeddedEditor().getDocument();
		// String result = doc.readOnly(new IUnitOfWork<String, XtextResource>() {
		// @Override
		// public String exec(XtextResource r) throws Exception {
		// Model m = (Model) r.getContents().get(0);
		// return interpret(m, monitor);
		// }
		// });
		// ref.set(result);
		// }
		// });
		// mqlv.getEmbeddedEditorResult().getDocument().set(ref.get());
		// } catch (InvocationTargetException e) {
		// e.printStackTrace();
		// } catch (InterruptedException e) {
		// e.printStackTrace();
		// }
		//
		// } else 
		if (activeEditor !== null && activeEditor instanceof XtextEditor) {
			val XtextEditor editor = (activeEditor as XtextEditor)
			val IProject project = ((editor.getEditorInput() as IFileEditorInput)).getFile().getProject()
			val Holder<String> ref = new Holder<String>()
			try {
				workbench.getProgressService().run(true, true, ([ IProgressMonitor monitor |
					var XtextDocument doc = (editor.getDocument() as XtextDocument)
					var String result = doc.readOnly(([ XtextResource r |
						var Model m = (r.getContents().get(0) as Model)
						return interpret(project, m, monitor)
					] as IUnitOfWork<String, XtextResource>))
					ref.set(result)
				] as IRunnableWithProgress))
			} catch (InvocationTargetException e) {
				e.printStackTrace()
			} catch (InterruptedException e) {
				e.printStackTrace()
			}

			System::out.println(ref.get()) // ModelQueryLanguageDialog dialog = new ModelQueryLanguageDialog(Display.getCurrent().getActiveShell(), ref.get(), project);
			// injector.injectMembers(dialog);
			// dialog.open();
		}
		return null
	}

	def protected XbaseInterpreter getConfiguredInterpreter(XtextResource resource) {
		var XbaseInterpreter interpreter2 = interpreterProvider.get()
		var ResourceSet set = resource.getResourceSet()
		var ClassLoader cl = getClass().getClassLoader()
		if (set instanceof XtextResourceSet) {
			// if this does not fit your needs have a look at XcoreJavaProjectProvider
			var Object context = ((set as XtextResourceSet)).getClasspathURIContext()
			if (context instanceof IJavaProject) {
				try {
					val IJavaProject jp = (context as IJavaProject)
					// String[] runtimeClassPath =
					// JavaRuntime.computeDefaultRuntimeClassPath(jp);
					// URL[] urls = new URL[runtimeClassPath.length];
					// for (int i = 0; i < urls.length; i++) {
					// urls[i] = new URL(runtimeClassPath[i]);
					// }
					// cl = new URLClassLoader(urls);
					var IClasspathEntry[] classpath = jp.getResolvedClasspath(true)
					val IWorkspaceRoot root = jp.getProject().getWorkspace().getRoot()
					var Set<URL> urls = Sets::<URL>newHashSet()
					for (var int i = 0; i < classpath.length; i++) {
						val IClasspathEntry entry = {
							val _rdIndx_classpath = i
							classpath.get(_rdIndx_classpath)
						}
						if (entry.getEntryKind() === IClasspathEntry::CPE_SOURCE) {
							var IPath outputLocation = entry.getOutputLocation()
							if (outputLocation === null) {
								outputLocation = jp.getOutputLocation()
							}
							var IFolder folder = root.getFolder(outputLocation)
							if (folder.exists()) {
								urls.add(new URL('''«folder.getRawLocationURI().toASCIIString()»/'''.toString))
							}
						} else if (entry.getEntryKind() === IClasspathEntry::CPE_PROJECT) {
							var IPath outputLocation = entry.getOutputLocation()
							if (outputLocation === null) {
								var IProject project = (jp.getProject().getWorkspace().getRoot().
									getContainerForLocation(entry.getPath()) as IProject)
								var IJavaProject javaProject = JavaCore::create(project)
								outputLocation = javaProject.getOutputLocation()
							}
							var IFolder folder = root.getFolder(outputLocation)
							if (folder.exists()) {
								urls.add(new URL('''«folder.getRawLocationURI().toASCIIString()»/'''.toString))
							}
						} else {
							urls.add(entry.getPath().toFile().toURI().toURL())
						}
					}
					System::out.println(urls)
					cl = new URLClassLoader(urls.toArray(newArrayOfSize(urls.size())), cl)
				} catch (Exception e) {
					e.printStackTrace()
				}

			}
		}
		interpreter2.setClassLoader(cl)
		return interpreter2
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

	def private String interpret(IProject project, Model m, IProgressMonitor monitor) {
		
		var IEvaluationContext context = new DefaultEvaluationContext()
		var XbaseInterpreter configuredInterpreter = getConfiguredInterpreter((m.eResource() as XtextResource))
		var String postfix = m.eResource().getURI().trimFileExtension().lastSegment()
		var XMap adapter = adapt(m.eResource())
		adapter.clear()
		val List<String> data = new ArrayList<String>()
		// context.newValue(qualifiedNameConverter.toQualifiedName(IModelQueryConstants.INFERRED_CLASS_NAME + postfix + "." + IModelQueryConstants.INDEX), resourceDescriptions);
		// context.newValue(qualifiedNameConverter.toQualifiedName(IModelQueryConstants.INFERRED_CLASS_NAME + postfix+ "." + IModelQueryConstants.RESOURCESET), resourceSetProvider.get());
		// context.newValue(qualifiedNameConverter.toQualifiedName(IModelQueryConstants.INFERRED_CLASS_NAME + postfix+ "." + IModelQueryConstants.PROJECT), project);
		// context.newValue(qualifiedNameConverter.toQualifiedName(IModelQueryConstants.INFERRED_CLASS_NAME + postfix + "." + IModelQueryConstants.INJECTOR), injector);
		if (m.getImportSection() !== null) {
			for (XImportDeclaration i : m.getImportSection().getImportDeclarations()) {
				data.add(serializer.serialize(i).trim())
			}
		}
		for (XMethodDeclaration d : m.getMethods()) {
			data.add(serializer.serialize(d).trim())
		}
		monitor.beginTask("Interpreting", m.getBody().getExpressions().size())
		for (XExpression x : m.getBody().getExpressions()) {
			if (monitor.isCanceled()) {
				System::out.println("mumu")
				monitor.done()
				return IterableExtensions::join(data, "\n")
			}
			var IEvaluationResult result = configuredInterpreter.evaluate(x, context, CancelIndicator::NullImpl)
			System::out.println('''!!!«result» : «result.getResult()»'''.toString)
			data.add(serializer.serialize(x).trim())
			if (result.getException() !== null) {
				data.add('''// Exception: «result.getException().getMessage()»'''.toString)
				result.getException().printStackTrace()
				return IterableExtensions::join(data, "\n")
			} else {
				adapter.put(x, new TraceData(serializer.serialize(x).trim(), cloner.clone(result.getResult()), null))
				if (x instanceof XMemberFeatureCall) {
					if (callMap.containsKey(((x as XMemberFeatureCall)).getFeature().getQualifiedName())) {
						var Integer idx = callMap.get(((x as XMemberFeatureCall)).getFeature().getQualifiedName())
						if (((x as XMemberFeatureCall)).getFeature().getQualifiedName().equals(
							"org.opencv.imgproc.Imgproc.HoughLinesP")) {
							adapter.put(x,
								new TraceData(serializer.serialize(x).trim(),
									cloner.clone(
										((configuredInterpreter as OpenCVInterpreter)).lastArgumentValues.get(idx)),
									DisplayConfig::MATRIX))
						} else
							adapter.put(x,
								new TraceData(serializer.serialize(x).trim(),
									cloner.clone(
										((configuredInterpreter as OpenCVInterpreter)).lastArgumentValues.get(idx)),
									null))
					}
				}
				if (result.getResult() === null) {
					data.add("// null")
				} else {
					data.add(
						'''//«result.getResult().getClass().getSimpleName()»: «result.getResult().toString()»'''.
							toString)
				}
			}
			monitor.worked(1)
		}
		monitor.done()
		return IterableExtensions::join(data, "\n")
	}

	override boolean isEnabled() {
		return true
	}

	static package class Holder<T> {
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
}
