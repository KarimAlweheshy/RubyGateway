//
//  RbObject.swift
//  RubyBridge
//
//  Distributed under the MIT license, see LICENSE
//
import RubyBridgeHelpers

/// Wraps a Ruby object
public final class RbObject {
    private let valueBox: UnsafeMutablePointer<Rbb_value>

    /// Wrap up a Ruby object using the `VALUE` handle
    /// returned by its API, keep the object safe from garbage collection.
    public init(rubyValue: VALUE) {
        valueBox = rbb_value_alloc(rubyValue);
    }

    /// Create another Swift reference to an existing `RbObject`.
    /// The underlying Ruby object will not be GCed until both
    /// `RbObject`s have gone out of scope.
    init(copy: RbObject) {
        valueBox = rbb_value_dup(copy.valueBox);
    }

    /// Allow the tracked object to be GCed when we go out of scope.
    deinit {
        rbb_value_free(valueBox)
    }

    /// Access the `VALUE` object handle for use with the `CRuby` API.
    ///
    /// If you keep hold of this `VALUE` after the `RbObject` has been
    /// deinitialized then you are responsible for making sure Ruby
    /// does not garbage collect it before you are done with it.
    ///
    /// It works best to keep the `RbObject` around and use this attribute
    /// accessor directly with the API
    public var rubyValue: VALUE {
        return valueBox.pointee.value
    }

    /// The Ruby type of this object.  This is fairly unfriendly enum but
    /// might be useful for debugging.
    public var rubyType: RbType {
        return TYPE(rubyValue)
    }

    /// Is the Ruby object truthy?
    public var isTruthy: Bool {
        return RB_TEST(rubyValue)
    }

    /// Is the Ruby object `nil`?
    ///
    /// If you've got Swift `nil` -- that is, you don't have `.some(RbObject)` --
    /// then Ruby failed - it raised an exception or something.
    ///
    /// If you've got Ruby `nil` -- this is, you've got `RbObject.isNil` -- then
    /// Ruby worked but the call evaluated to `nil`.
    public var isNil: Bool {
        return RB_NIL_P(rubyValue)
    }
}

/// Give access to classes/modules/constants nested under this class/object.
extension RbObject: RbConstantScope {
    func constantScopeValue() throws -> VALUE {
        return rubyValue
    }
}
