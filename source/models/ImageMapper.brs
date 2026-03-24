' ******************************************************
' ImageMapper.brs - DEBUG VERSION
' Maps Flickr API JSON to ImageModel
' ******************************************************

function ImageMapper() as Object
    return {
        fromFlickrJSON: ImageMapper_fromFlickrJSON
        mapImageUrls: ImageMapper_mapImageUrls
        mapMetadata: ImageMapper_mapMetadata
        mapStats: ImageMapper_mapStats
        validate: ImageMapper_validate
    }
end function


' Convert Flickr JSON to ImageModel
function ImageMapper_fromFlickrJSON(json as Object) as Object
    ' Validate required fields
    if not m.validate(json) then
        return invalid
    end if
    
    ' Create base model
    model = CreateImageModel()
    
    ' Map core fields
    model.id = json.id
    model.title = json.title
    if model.title = invalid or model.title = "" then
        model.title = "Untitled"
    end if
    
    ' Map URLs
    model = m.mapImageUrls(model, json)
    
    ' Map metadata
    model = m.mapMetadata(model, json)
    
    ' Map stats
    model = m.mapStats(model, json)
    
    return model
end function


' Map image URLs - use URLs directly from API extras or build them
function ImageMapper_mapImageUrls(model as Object, json as Object) as Object
    ' Flickr API provides URLs directly when using extras parameter
    ' Priority: Use direct URLs if available, otherwise build them
    
    if json.url_q <> invalid and json.url_q <> "" then
        model.url_thumbnail = json.url_q
    else
        urlBuilder = ImageUrlBuilder()
        model.url_thumbnail = urlBuilder.build(json, "q")
    end if
    
    if json.url_n <> invalid and json.url_n <> "" then
        model.url_small = json.url_n
    else
        urlBuilder = ImageUrlBuilder()
        model.url_small = urlBuilder.build(json, "n")
    end if
    
    if json.url_z <> invalid and json.url_z <> "" then
        model.url_medium = json.url_z
    else
        urlBuilder = ImageUrlBuilder()
        model.url_medium = urlBuilder.build(json, "z")
    end if
    
    if json.url_b <> invalid and json.url_b <> "" then
        model.url_large = json.url_b
    else
        urlBuilder = ImageUrlBuilder()
        model.url_large = urlBuilder.build(json, "b")
    end if
    
    return model
end function


' Map metadata
function ImageMapper_mapMetadata(model as Object, json as Object) as Object
    ' Owner
    if json.owner <> invalid then
        model.owner_id = json.owner
    end if
    
    if json.ownername <> invalid then
        model.owner_name = json.ownername
    end if
    
    ' Description
    if json.description <> invalid then
        if Type(json.description) = "roAssociativeArray" and json.description._content <> invalid then
            model.description = json.description._content
        else if Type(json.description) = "roString" or Type(json.description) = "String" then
            model.description = json.description
        end if
    end if
    
    ' Tags - can be string or array
    if json.tags <> invalid then
        if Type(json.tags) = "roArray" then
            ' Join array into comma-separated string
            model.tags = ""
            for each tag in json.tags
                if model.tags <> "" then model.tags = model.tags + ","
                model.tags = model.tags + tag
            end for
        else if Type(json.tags) = "roString" or Type(json.tags) = "String" then
            model.tags = json.tags
        end if
    end if
    
    ' Upload date
    if json.dateupload <> invalid then
        model.date_upload = json.dateupload
    end if
    
    return model
end function


' Map statistics
function ImageMapper_mapStats(model as Object, json as Object) as Object
    if json.views <> invalid then
        if Type(json.views) = "roString" or Type(json.views) = "String" then
            model.views = json.views.ToInt()
        else
            model.views = json.views
        end if
    end if
    
    return model
end function


' Validate required fields
function ImageMapper_validate(json as Object) as Boolean
    if json = invalid then
        print "[ImageMapper] ERROR: JSON is invalid"
        return false
    end if
    
    if json.id = invalid or json.id = "" then
        print "[ImageMapper] ERROR: Missing id"
        return false
    end if
    
    ' Title is optional, but log if missing
    if json.title = invalid or json.title = "" then
        print "[ImageMapper] WARNING: Missing title for image "; json.id
    end if
    
    return true
end function
