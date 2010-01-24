
Share Craft Queue will maintain a list of items to be crafted and mail
that list to another toon.  

The tracking list is the items that you want to always have on hand.

The queue is all the items that currently need to be crafted.

You track items that you want crafted and then add then queue items to
be crafted.

    /scq send recipient -- send the mail
    /scq list -- list all the items that are being tracked
    /scq add count name -- track this item
    /scq rm name -- don't track this item
    /scq rmall -- remove all tracked items
    /scq queue count name -- add count items to the queue
    /scq reset -- empty the queue
    /scq scan -- reset and add tracked items to the queue
    /scq show -- show the crafting queue
    /scq add-glyphs count -- track all the glyphs
    /scq read -- read the mail message
    /scq insert-craft -- Add our queue to the QA crafting queue

/scq scan will examine your bags, bank, and auction house (if you have
the AH targeted) and add missing tracked items to the queue.

Chris Dean
21 Jan 2010
