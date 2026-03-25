' ImageModel.brs
' Pure data model for Flickr image

function CreateImageModel() as Object
    return {
        ' Core properties
        id: ""
        title: ""
        description: ""
        
        ' Owner info
        owner: ""
        ownerId: ""
        
        ' Image URLs (different sizes)
        url_thumbnail: ""   ' 150x150
        url_small: ""       ' 320px
        url_medium: ""      ' 640px
        url_large: ""       ' 1024px
        
        ' Metadata
        width: 0
        height: 0
        tags: []
        datePosted: ""
        views: 0
    }
end function