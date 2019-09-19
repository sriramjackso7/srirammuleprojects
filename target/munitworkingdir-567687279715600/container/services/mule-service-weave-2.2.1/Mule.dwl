/**
* This DataWeave module contains functions for interacting with Mule runtime.
*/
%dw 2.0

/**
* Type that represents an Error.
*/
type Error = {
    /**
    * Concise description of the error.
    */
    description?: String,
    /**
    * Detailed description of the error. This message can include information
    * specific to a Java exception.
    */
    detailedDescription?: String,
    /**
    * Returns the type of the error.
    */
    errorType?: ErrorType,
    /**
    * Lists child Errors, if any.
    *
    * For example, the Scatter-Gather router might throw an error aggregating
    * all of its routes errors as children.
    *
    * Not all failing components aggregate errors, so this type can return an
    * empty collection.
    */
    childErrors?: Array<Error>
}

/**
* Type that represents a Mule Message
*/
type Message = Object {class: "org.mule.runtime.api.message.Message"}

/**
* A type of error that a Mule component can throw.
*
*
* The error type has a `identifier` string that end users can provide
* in the Mule configuration.
*
* Every error belongs to a `namespace` to avoid collisions with errors that
* have the same `identifier` string but belong to different namespace.
*
* Error types can be a specialization of a more general error type, in which
* case the `parentErrorType` should return the more general error type. This
* type is used during error type matching within error handlers. So when
* selecting the general error type for error handling, it also handles the
* more specialized error types.
*/
type ErrorType = {
    identifier?: String,
    namespace?: String,
    parentErrorType?: ErrorType
}

/**
* This function enables you to execute a flow within a Mule app and
* retrieve the resulting payload.
*
*
* It works in Mule apps that are running on Mule Runtime version 4.1.4 and
* later.
*
* Similar to the Flow Reference component (recommended), the `lookup` function
* enables you to execute another flow within your app and to retrieve the
* resulting payload. It takes the flow's name and an input payload as
* parameters. For example, `lookup("anotherFlow", payload)` executes a flow
* named `anotherFlow`.
*
* The function executes the specified flow using the current attributes,
* variables, and any error, but it only passes in the payload without any
* attributes or variables. Similarly, the called flow will only return
* its payload.
*
* Note that `lookup` function does not support calling subflows.
*
* === Parameters
*
* [%header, cols="1,3"]
* |===
* | Name | Description
* | `flowName` | A string that identifies the target flow.
* | `payload` | The payload to send to the target flow, which can be any (`Any`) type.
* | `timeoutMillis` | Optional. Timeout (in milliseconds) for the execution of the target flow. Defaults to `2000` milliseconds (2 seconds) if the thread that is executing is CPU_LIGHT or CPU_INTENSIVE, or 1 minute when executing from other threads. If the lookup takes more time than the specified `timeoutMillis` value, an error is raised.
* |===
*
* === Example
*
* This example shows XML for two flows. The `lookup` function in `flow1` executes
* `flow2` and passes the object `{test:'hello '}` as its payload to `flow2`. The
* Set Payload component  (`<set-payload/>`) in `flow2` then concatenates the
* value  of `{test:'hello '}` with the string `world` to output and log
* `hello world`.
*
* ==== Source
*
* [source,XML,linenums]
* ----
* <flow name="flow1">
*   <http:listener doc:name="Listener" config-ref="HTTP_Listener_config"
*     path="/source"/>
*   <ee:transform doc:name="Transform Message" >
*     <ee:message >
*       <ee:set-payload ><![CDATA[%dw 2.0
* output application/json
* ---
* Mule::lookup('flow2', {test:'hello '})]]></ee:set-payload>
*     </ee:message>
*   </ee:transform>
* </flow>
* <flow name="flow2" >
*   <set-payload value='#[payload.test ++ "world"]' doc:name="Set Payload" />
*   <logger level="INFO" doc:name="Logger" message='#[payload]'/>
* </flow>
* ----
*/
fun lookup(flowName: String, payload: Any, timeoutMillis: Number = 2000) =
    dw::mule::internal::Bindings::callFunction("", "lookup", [flowName, payload, timeoutMillis])


/**
* This function returns a string that identifies the value of one of these
* input properties: Mule property placeholders, System properties, or
* Environment variables.
*
*
* For more on this topic, see
* https://docs.mulesoft.com/mule-runtime/4.1/configuring-properties[Configure Properties].
*
* === Parameters
*
* [%header, cols="1,3"]
* |===
* | Name | Description
* | `propertyName` | A string that identifies property.
* |===
*
* === Example
*
* This example logs the value of the property `http.port` in a Logger component.
*
* ==== Source
*
* [source,xml,linenums]
* ----
* <flow name="simple">
*  <logger level="INFO" doc:name="Logger"
*    message="#[Mule::p('http.port')]"/>
* </flow>
* ----
*/
fun p(propertyName: String): String =
    dw::mule::internal::Bindings::callFunction("", "p", [propertyName])

/**
* This function matches an error by its type, like an error handler does.
*
*
* `causedBy` is useful when you need to match by a super type, but the
* specific sub-type logic is also needed. It can also useful when handling a
* COMPOSITE_ROUTING error that contains child errors of different types.
*
* === Parameters
*
* [%header, cols="1,3"]
* |===
* | Name | Description
* | `error` | Optional. An `Error` type.
* | `errorType` | A string that identifies the error, such as HTTP:UNAUTHORIZED.
* |===
*
* === Example
*
* This XML example calls `causedBy` from a `when` expression in a Mule error
* handling component to handle a SECURITY error differently depending on whether
* it was caused by an HTTP:UNAUTHORIZED or HTTP:FORBIDDEN error. Notice that the
* first expression passes in the `error` (an `Error` type) explicitly, while the
* second one passes it implicitly, without specifying the value of the parameter.
* Note that `error` is the variable that DataWeave uses for errors associated
* with a Mule message object (see
* https://docs.mulesoft.com/mule-runtime/4.1/dataweave-variables-context[DataWeave Variables for Mule Runtime]).
*
* ==== Source
*
* [source,XML,linenums]
* ----
* <error-handler name="securityHandler">
*   <on-error-continue type="SECURITY">
*     <!-- general error handling for all SECURITY errors -->
*     <choice>
*       <when expression="#[Mule::causedBy(error, 'HTTP:UNAUTHORIZED')]">
*         <!-- specific error handling only for HTTP:UNAUTHORIZED errors -->
*       </when>
*       <when expression="#[Mule::causedBy('HTTP:FORBIDDEN')]">
*         <!-- specific error handling only for HTTP:FORBIDDEN errors -->
*       </when>
*     </choice>
*   </on-error-continue>
* </error-handler>
* ----
**/
fun causedBy(error: Error, errorType: String): Boolean =
    dw::mule::internal::Bindings::callFunction("", "causedBy", [error, errorType])
