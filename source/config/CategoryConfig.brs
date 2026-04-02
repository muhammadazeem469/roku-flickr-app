

function GetCategories() as Object
    return [
        {
            name: "Featured"
            method: "flickr.interestingness.getList"
            tags: ""
            display_name: "Featured"
            description: "Most interesting photos on Flickr"
        }
        {
            name: "Nature"
            method: "flickr.photos.search"
            tags: "nature,landscape,mountains,forest,wildlife"
            display_name: "Nature"
            description: "Beautiful landscapes and wildlife"
        }
        {
            name: "Architecture"
            method: "flickr.photos.search"
            tags: "architecture,building,cityscape,urban"
            display_name: "Architecture"
            description: "Buildings and urban landscapes"
        }
        {
            name: "Animals"
            method: "flickr.photos.search"
            tags: "animals,wildlife,pets,birds,cats,dogs"
            display_name: "Animals"
            description: "Wildlife and pets"
        }
        {
            name: "Historical"
            method: "flickr.photos.search"
            tags: "history,vintage,historical,heritage,monument"
            display_name: "Historical"
            description: "Historical photos and monuments"
        }
        {
            name: "Technology"
            method: "flickr.photos.search"
            tags: "technology,tech,gadgets,innovation,digital"
            display_name: "Technology"
            description: "Tech and innovation"
        }
        {
            name: "Travel"
            method: "flickr.photos.search"
            tags: "travel,vacation,tourism,destination,adventure"
            display_name: "Travel"
            description: "Travel destinations and adventures"
        }
        {
            name: "Food"
            method: "flickr.photos.search"
            tags: "food,cooking,cuisine,recipe,restaurant"
            display_name: "Food"
            description: "Delicious food and cuisine"
        }
        {
            name: "Sports"
            method: "flickr.photos.search"
            tags: "sports,fitness,athlete,game,competition"
            display_name: "Sports"
            description: "Sports and athletics"
        }
        {
            name: "Art"
            method: "flickr.photos.search"
            tags: "art,painting,sculpture,creative,artistic"
            display_name: "Art"
            description: "Artistic creations and paintings"
        }
        {
            name: "People"
            method: "flickr.photos.search"
            tags: "people,portrait,faces,human,person"
            display_name: "People"
            description: "Portraits and people"
        }
        {
            name: "Popular"
            method: "flickr.photos.getPopular"
            tags: ""
            display_name: "Popular"
            description: "Most popular photos on Flickr"
        }
        {
            name: "Recent"
            method: "flickr.photos.getRecent"
            tags: ""
            display_name: "Recent Uploads"
            description: "Latest uploads on Flickr"
        }
    ]
end function

' Get category by name
function GetCategoryByName(categoryName as String) as Object
    categories = GetCategories()
    for each category in categories
        if category.name = categoryName then
            return category
        end if
    end for
    return invalid
end function