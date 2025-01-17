//
//  PageHandler.swift
//  PerfectLib
//
//  Created by Kyle Jessup on 7/8/15.
//	Copyright (C) 2015 PerfectlySoft, Inc.
//
//	This program is free software: you can redistribute it and/or modify
//	it under the terms of the GNU Affero General Public License as
//	published by the Free Software Foundation, either version 3 of the
//	License, or (at your option) any later version, as supplemented by the
//	Perfect Additional Terms.
//
//	This program is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU Affero General Public License, as supplemented by the
//	Perfect Additional Terms, for more details.
//
//	You should have received a copy of the GNU Affero General Public License
//	and the Perfect Additional Terms that immediately follow the terms and
//	conditions of the GNU Affero General Public License along with this
//	program. If not, see <http://www.perfect.org/AGPL_3_0_With_Perfect_Additional_Terms.txt>.
//

private let GLOBAL_HANDLER = "%GLOBAL%"

/// Use this class to register handlers which supply values for moustache templates.
/// This registration would occur in the `PerfectServerModuleInit` function which every PerfectServer library module should define. PerfectServer will call this method when it loads each module as the server process starts up.
///
/// Example:
///```
///	public func PerfectServerModuleInit() {
///		PageHandlerRegistry.addPageHandler("test_page_handler") {
///			(r: WebResponse) -> PageHandler in
///			return MyTestHandler()
///		}
///	}
///```
///
/// In the example above, the class MyTestHandler is registering to be the handler for moustache templates which include a handler
/// pragma with the `test_page_handler` identifier.
///
/// The following example shows what such a moustache template file might look like:
///```
///    {{% handler:test_page_handler }}
///    Top of the page test {{key1}}
///    {{key2}}
///    That's all
///```
public class PageHandlerRegistry {
	/// A function which returns a new PageHandler object given a WebRequest
	public typealias PageHandlerGenerator = (_:WebResponse) -> PageHandler
	
	/// Registers a new handler for the given name
	/// - parameter named: The name for the handler. This name should be used in a moustache `handler` pragma tag in order to associate the template with its handler.
	/// - parameter generator: The generator function which will be called to produce a new handler object.
	public static func addPageHandler(named: String, generator: PageHandlerGenerator) {
		PageHandlerRegistry.generator[named] = generator
	}
	
	/// Registers a new handler as a fallback for any response template.
	/// Templates which do not have a %handler pragma will use this handler.
	/// - parameter generator: The generator function which will be called to produce a new handler object.
	public static func addPageHandler(generator: PageHandlerGenerator) {
		PageHandlerRegistry.generator[GLOBAL_HANDLER] = generator
	}
	
	/// Registers a new handler for the given name
	/// - parameter named: The name for the handler. This name should be used in a moustache `handler` pragma tag in order to associate the template with its handler.
	/// - parameter generator: The generator function which will be called to produce a new handler object.
	public static func addPageHandler(named: String, generator: () -> PageHandler) {
		addPageHandler(named) {
			(_:WebResponse) -> PageHandler in
			return generator()
		}
	}
	
	private static var generator = Dictionary<String, PageHandlerGenerator>()
	
	static func getPageHandler(named: String, forResponse: WebResponse) -> PageHandler? {
		let h = PageHandlerRegistry.generator[named]
		if let fnd = h {
			return fnd(forResponse)
		}
		return nil
	}
	
	static func getPageHandler(forResponse: WebResponse) -> PageHandler? {
		let h = PageHandlerRegistry.generator[GLOBAL_HANDLER]
		if let fnd = h {
			return fnd(forResponse)
		}
		return nil
	}
}

/// Classes which intend to supply values for moustache templates should impliment this protocol.
public protocol PageHandler {
	/// This function is called by the system in order for the handler to generate the values which will be used to complete the moustache template.
	/// It returns a dictionary of values.
	/// - parameter context: The MoustacheEvaluationContext object for the current template.
	/// - parameter collector: The MoustacheEvaluationOutputCollector for the current template.
	/// - returns: The dictionary of values which will be used when populating the moustache template.
	func valuesForResponse(context: MoustacheEvaluationContext, collector: MoustacheEvaluationOutputCollector) throws -> MoustacheEvaluationContext.MapType
	
}
