# Overall

Most general comments/thoughts are in the Notes and Thoughts document in the off-line course folder.

# Notes

-   I'm doing local rendering into the docs folder and syncing/pushing it instead of using gh-pages workflow.

# Andreas ToDo







# Old Todo, some addressed

-   Is there an easier way to do internal referencing to files?
    Having to remember the local structure is unwieldy and fragile.
    For instance this is cumbersome: I got [this code](../../../code/bing-iterate-example-update1.R).
    Instead, I'd like to just write [this code](bing-iterate-example-update1.R) and let Quarto figure out where the file is.
    Is there a way to maybe define a file that contains all the path mappings?
    This way it would be easier to write, and also if I change things around, I don't have to update all links.

    -   I found this [Quarto specific solution](https://github.com/quarto-dev/quarto-cli/discussions/6334#discussioncomment-6541441). Using the folder/file syntax like `/code/bing-iterate-example-update1.R` will ensure the path is always resolved with respect to the website root.

-   Can we change color scheme to something less stark/dark?
    And could we have a light and dark scheme?

    -   Hopefully this is better. As for the light and dark scheme, it is possible. But the dark mode will [flash white when changing pages](https://github.com/quarto-dev/quarto-cli/discussions/2588#discussioncomment-6092667) which is annoying for most people and especially problematic for folks with photosensitive epilepsy.

-   Make the callout block divs nicer.

-   Can one make the images larger, they are at times hard to see/read.
    And could one do that in a way that they can be 'centrally controlled', like the CSS code fo the video sizing?

    -   I added the [lightbox extension](https://github.com/quarto-ext/lightbox) which is a javascript library that allows the user to click on an image to open it full screen.
        See lines 41-49 in `_quarto.yml` for options.

    -   If there's a particular image you want to make larger, you can use the syntax `"width=800px"` inside the curly braces, like `![In this course, I randomly switch back and forth between singular and plural. Source: phdcomics.com.](../../media/phd_dataisorare.gif){width="800px" fig-alt="A four panel PhD comic.'"}`

-   Switch most of the bold text blocks to callouts/divs.
    Add more divs/callout categories as needed.


-   Try to eventually have consistent naming of folders and files: All lowercase, with dashes as separators https://developers.google.com/style/filenames

    -   ✅ done, used the below code to rename everything. Then manually edited the yml with the find and replace feature.

```         
files <- fs::dir_ls("content", recurse = TRUE)
file.rename(files, stringr::str_replace_all(files, pattern = "_", "-"))
files <- fs::dir_ls("content", recurse = TRUE)
file.rename(files, tolower(files))
```

-   Is there a way to automatically reverse-check to see if all files in /media/ are actually being used in at least one of the Quarto documents?

    -   Not off the top of the head, but probably could write a script to list all files in the media folder, read all lines in the .qmd files, and then use stringr::str_detect or stringr::str_match_all?

-   Wrap all AI prompts in the files inside the ::: prompt div

-   Eventually, each unit should have these sections: \# Overview \# Learning Objectives \# Introduction \# Topic 1 \## Subtopic 1 \## Subtopic 2 \# Topic 2 \## Subtopic 1 ... \# Summary \# Further Resources

-   Update links/references to R4DS 2nd edition instead of 1st.

    -   Did most of them but there isn't a tibble or model chapter in the second edition. `content/module-data-intro/data-types.qmd` now has a broken link since it references the tibble chapter.

-   Write table unit


# Notes from Quarto conversion by Jadey

## Checking links for 404 or other errors

After publishing, I like to run the site url through [Dr Link Check](https://www.drlinkcheck.com/) and fix links accordingly. The report will show you which files contain the broken links.

## Emojis

Quarto allows you to insert emojis without the `emoji` package.
<https://quarto.org/docs/visual-editor/content.html#emojis>

You can insert emojis without the visual editor.
on Windows, the shortcut is `Windows + .` on Mac: `Ctrl + Cmd + Space`

For output to a different format, add this to the YAML heading of the file.

```         
---
title: "Word doc report"
format: docx
from: markdown+emoji
---
```

### Navigation

Your site uses hybrid navigation (navbar plus sidebar) as detailed in these [Quarto docs](https://quarto.org/docs/websites/website-navigation.html#hybrid-navigation).

Note the text in the navbar matches the title in the sidebar and the files are the same.
The sidebar style, collapse-level, and other options don't need to be included in other sidebars (unless you want a different setting for a specific sidebar).

## Cross reference website pages

Use the `.qmd` file rather than the `.html` per the [Quarto docs](https://quarto.org/docs/websites/#linking).

To link between pages **within the same** folder - just use the name of the other file.

Example as seen in `courseinfo/Course_Syllabus.qmd`: `[_Assessments page_](Course_Assessments.qmd)`

To link between pages in **different** folders - use double dots to get to the parent directory and then the desired folder name.

Example as seen in `assessments/Assessment_Course_Tools_Introduction.qmd`: `[**Schedule**](../courseinfo/Course_Schedule.qmd)`

This way of cross referencing is cool because you can link to specific sections.
Add a `#sec-` identifier to any heading per these [Quarto docs](https://quarto.org/docs/authoring/cross-references.html#sections).

## Contributors - author roles in metadata

In `Data_Exploration.qmd` and `Data_Wrangling.qmd`, you had a contributors field which isn't valid in Quarto.
Beginning in Quarto 1.4, authors will have a `role` key available per this [stack overflow Q/A](https://stackoverflow.com/questions/77046856/how-to-get-author-roles-defined-in-quarto-document-to-appear-in-output).
So for now both names show as authors.

```         
---
title: Exploring Data  
subtitle: ""
authors: 
  - name: Andreas Handel
  - name: Megan Beaudry
    role: "Contributor"
---
```

## Images

You can also use markdown image syntax instead of `knitr::include_graphics()`.
It might be more efficient when rendering since it doesn't require execution [Quarto figures](https://quarto.org/docs/authoring/figures.html) though I haven't tested this.
Anyway, it's more aligned with "the Quarto way" and `fig-align` is set to center in `_quarto.yml` so it doesn't need to be repeated for each figure.

Note: the global fig-align setting in the yaml applies to figures which Quarto defines as having a label and caption.
Supposedly this will get fixed in Quarto 1.4 according to this [issue](https://github.com/quarto-dev/quarto-cli/issues/4315#issuecomment-1444304192).
To get around this until the next release, we need to make sure all images have captions OR set fig-align="center" for the individual image that doesn't have a caption.

## Video iframes

I added a couple of css rules to `MADAstyle.scss` so you don't have to add all the styling to every iframe based on this [article](https://www.h3xed.com/web-development/how-to-make-a-responsive-100-width-youtube-iframe-embed).
This also improves consistency and responsiveness between different video websites (Ted vs YouTube) and across different screen sizes.

Instead of:

```         
Ted Talk embedded video
<p>
<iframe src="https://embed.ted.com/talks/sebastian_wernicke_how_to_use_data_to_make_a_hit_tv_show" width="640" height="360" frameborder="0" scrolling="no" webkitAllowFullScreen mozallowfullscreen allowFullScreen></iframe>
</p>

YouTube embedded video
<p>
<iframe width="560" height="315" src="https://www.youtube.com/embed/2HpRXIpU4jI" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</p>
```

You create a div with the class `container` then set the iframe class to `video` for any video you want to embed in an iframe.
Remove the width/height in the embed code so that the CSS takes over and sets it dynamically to 100% of the screen width.

```         
# Ted Talk 
::: container 
<iframe class="video" src="https://embed.ted.com/talks/sebastian_wernicke_how_to_use_data_to_make_a_hit_tv_show" frameborder="0" scrolling="no" allowfullscreen></iframe>
:::

#YouTube 
::: container
<iframe class="video" src="https://www.youtube.com/embed/2HpRXIpU4jI" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe> 
:::
```

## Accessibility

Accessibility is really important to me so I thought I'd call attention to some of your hyperlink names.
Most are great (concise and descriptive) but some are just called \[here\] which aren't [helpful link names](https://www.a11yproject.com/posts/creating-valid-and-accessible-links/)
