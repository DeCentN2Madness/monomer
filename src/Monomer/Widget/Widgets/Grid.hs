module Monomer.Widget.Widgets.Grid (
  hgrid,
  vgrid
) where

import Control.Monad
import Data.Default
import Data.List (foldl')
import Data.Sequence (Seq(..), (|>))

import qualified Data.Sequence as Seq

import Monomer.Common.Geometry
import Monomer.Common.Tree
import Monomer.Widget.Types
import Monomer.Widget.Util
import Monomer.Widget.BaseContainer

hgrid :: (Traversable t) => t (WidgetInstance s e) -> WidgetInstance s e
hgrid children = (defaultWidgetInstance "hgrid" (makeFixedGrid True)) {
  _instanceChildren = foldl' (|>) Empty children
}

vgrid :: (Traversable t) => t (WidgetInstance s e) -> WidgetInstance s e
vgrid children = (defaultWidgetInstance "vgrid" (makeFixedGrid False)) {
  _instanceChildren = foldl' (|>) Empty children
}

makeFixedGrid :: Bool -> Widget s e
makeFixedGrid isHorizontal = createContainer {
    _widgetPreferredSize = containerPreferredSize preferredSize,
    _widgetResize = containerResize resize
  }
  where
    preferredSize renderer app widgetInstance childrenPairs = Node reqSize children where
      children = fmap snd childrenPairs
      visiblePairs = Seq.filter (_instanceVisible . fst) childrenPairs
      childrenReqs = fmap (nodeValue . snd) visiblePairs
      reqSize = SizeReq (Size width height) FlexibleSize FlexibleSize
      width = if Seq.null children then 0 else fromIntegral wMul * (maximum . fmap (_w . _sizeRequested)) childrenReqs
      height = if Seq.null children then 0 else fromIntegral hMul * (maximum . fmap (_h . _sizeRequested)) childrenReqs
      wMul = if isHorizontal then length children else 1
      hMul = if isHorizontal then 1 else length children

    resize app viewport renderArea widgetInstance childrenPairs = (widgetInstance, assignedAreas) where
      visiblePairs = Seq.filter (_instanceVisible . fst) childrenPairs
      children = fmap fst visiblePairs
      Rect l t w h = renderArea
      cols = if isHorizontal then length visiblePairs else 1
      rows = if isHorizontal then 1 else length visiblePairs
      foldHelper (newAreas, index) child = (newAreas |> newArea, newIndex) where
        visible = _instanceVisible child
        newIndex = index + if _instanceVisible child then 1 else 0
        newViewport = if visible then calcViewport index else def
        newArea = (newViewport, newViewport)
      assignedAreas = fst $ foldl' foldHelper (Seq.empty, 0) children
      calcViewport i = Rect (cx i) (cy i) cw ch
      cw = if cols > 0 then w / fromIntegral cols else 0
      ch = if rows > 0 then h / fromIntegral rows else 0
      cx i = if rows > 0 then l + fromIntegral (i `div` rows) * cw else 0
      cy i = if cols > 0 then t + fromIntegral (i `div` cols) * ch else 0
