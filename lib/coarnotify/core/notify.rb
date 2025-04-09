=begin
This module is home to all the core model objects from which the notify patterns extend
=end

require "coarnotify/core/activitystreams2"

NOTIFY_NAMESPACE = "https://coar-notify.net"
# Namespace for COAR Notify, to be used to construct namespaced properties used in COAR Notify Patterns"""

class NotifyProperties

    # COAR Notify properties used in COAR Notify Patterns

    # Most of these are provided as tuples, where the first element is the property name, and the second element is the namespace.
    # Some are provided as plain strings without namespaces

    # These are suitable to be used as property names in all the property getters/setters in the notify pattern objects
    # and in the validation configuration.


    INBOX = ("inbox", NOTIFY_NAMESPACE)
    # `inbox` property

    CITE_AS = ("ietf:cite-as", NOTIFY_NAMESPACE)
    # `ietf:cite-as` property
    ITEM = ("ietf:item", NOTIFY_NAMESPACE)
    # `ietf:item` property

    NAME = "name"
    # `name` property

    MEDIA_TYPE = "mediaType"
    # `mediaType` property
end


class NotifyTypes

    # List of all the COAR Notify types patterns may use.

    # These are in addition to the base Activity Streams types, which are in :rb:class:`coarnotify.core.activitystreams2.ActivityStreamsTypes`

    ENDORSMENT_ACTION = "coar-notify:EndorsementAction"
    INGEST_ACTION = "coar-notify:IngestAction"
    RELATIONSHIP_ACTION = "coar-notify:RelationshipAction"
    REVIEW_ACTION = "coar-notify:ReviewAction"
    UNPROCESSABLE_NOTIFICATION = "coar-notify:UnprocessableNotification"

    ABOUT_PAGE = "sorg:AboutPage"
end

__VALIDATION_RULES = {
    ActivityStream::Properties::ID => {
        "default" => -> (value) { Validate }
    }
}
