' ContentNodeConverter.brs
' Converts ImageModel to SceneGraph ContentNode

function ContentNodeConverter() as Object
    return {
        fromImageModel: ContentNodeConverter_fromImageModel
    }
end function


' Convert ImageModel to ContentNode
function ContentNodeConverter_fromImageModel(imageModel as Object) as Object
    if imageModel = invalid then
        print "[ContentNodeConverter] Invalid ImageModel"
        return invalid
    end if
    
    node = CreateObject("roSGNode", "ContentNode")
    
    ' Standard SceneGraph fields
    node.title = imageModel.title
    node.description = imageModel.description
    node.HDPosterUrl = imageModel.url_large
    node.FHDPosterUrl = imageModel.url_large
    node.SDPosterUrl = imageModel.url_medium
    
    ' Custom fields for detail view
    node.addFields({
        imageId: imageModel.id
        thumbnailUrl: imageModel.url_thumbnail
        smallUrl: imageModel.url_small
        mediumUrl: imageModel.url_medium
        largeUrl: imageModel.url_large
        imageWidth: imageModel.width
        imageHeight: imageModel.height
        ownerName: imageModel.owner
        ownerId: imageModel.ownerId
        tags: imageModel.tags
        datePosted: imageModel.datePosted
        viewCount: imageModel.views
    })
    
    return node
end function