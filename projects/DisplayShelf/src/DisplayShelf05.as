package
{
	import mx.core.UIComponent;
	import flash.filters.DropShadowFilter;
	import flash.geom.Matrix;
	import flash.events.TimerEvent;
	import flash.events.MouseEvent;
	import flash.utils.Dictionary;
	import flash.events.Event;
	import mx.managers.IHistoryManagerClient;
	import mx.managers.HistoryManager;
	import mx.controls.Image;
	import mx.events.CollectionEvent;
	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	import mx.collections.XMLListCollection;
	import mx.managers.IFocusManagerComponent;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import mx.core.IFactory;
	import mx.core.IDataRenderer;
	import mx.core.ClassFactory;

	[DefaultProperty("dataProvider")]
	public class DisplayShelf05 extends UIComponent implements IFocusManagerComponent
	{
		//---------------------------------------------------------------------------------------
		// constructor
		//---------------------------------------------------------------------------------------

		public function DisplayShelf05()
		{
			super();
			dataProvider = new ArrayCollection();
			_itemRenderer = new ClassFactory(Image);
		}


		//---------------------------------------------------------------------------------------
		// constants
		//---------------------------------------------------------------------------------------
		
		private const kPaneOverlap:Number = 40;
		private const kMaxSelectionVelocity:Number = .6;

		//---------------------------------------------------------------------------------------
		// private state
		//---------------------------------------------------------------------------------------

		private var _popout:Number = .43;
		private var _children:Array = [];
		private var _angle:Number = 35;
		private var _selectedIndex:Number = 0;		
		private var lCP:ChildPosition = new ChildPosition();
		private var rCP:ChildPosition = new ChildPosition();
		private var _safeSelectedIndex:Number;

		private var _dataProvider:IList;
		private var _itemRenderer:IFactory;
		private var _itemsDirty:Boolean = true;
		
		//---------------------------------------------------------------------------------------
		// public properties
		//---------------------------------------------------------------------------------------
		
		public function set popout(value:Number):void
		{
			_popout = value;
			invalidateDisplayList();
		}
		public function get popout():Number
		{
			return _popout;
		}
		
		[Bindable]
		public function set selectedIndex(value:Number):void
		{
			if(_selectedIndex == value)
				return;
				
			_selectedIndex = value;
			
			_safeSelectedIndex = Math.max(0,Math.min(_selectedIndex,_children.length-1));
			invalidateDisplayList();
		}
		
		public function get selectedIndex():Number
		{
			return _selectedIndex;
		}

		[Bindable] public function set dataProvider(value:Object):void
		{
			if(_dataProvider != null)
			{
				_dataProvider.removeEventListener(CollectionEvent.COLLECTION_CHANGE,dataChangeHandler);
			}
	        if (value is Array)
	        {
	            _dataProvider = new ArrayCollection(value as Array);
	        }
	        else if (value is IList)
	        {
	            _dataProvider = IList(value);
	        }
			else if (value is XMLList)
			{
				_dataProvider = new XMLListCollection(value as XMLList);
			}
			_dataProvider.addEventListener(CollectionEvent.COLLECTION_CHANGE,dataChangeHandler);			
			_itemsDirty = true;
			invalidateProperties();
			invalidateSize();
		}
		public function get dataProvider():Object
		{
			return _dataProvider;
		}

		public function set itemRenderer(value:IFactory):void
		{
			_itemRenderer = value;
			_itemsDirty = true;
			invalidateProperties();
			invalidateSize();			
		}
		public function get itemRenderer():IFactory
		{
			return _itemRenderer;
		}

		public function set angle(value:Number):void
		{		
			_angle = value;
			invalidateDisplayList();
		}
		
		public function get angle():Number
		{
			return _angle;
		}
		
		//---------------------------------------------------------------------------------------
		// property management
		//---------------------------------------------------------------------------------------

		override protected function commitProperties():void
		{
			if(_itemsDirty)
			{
				_itemsDirty = false;
				for(var i:int = 0;i<_dataProvider.length;i++)
				{
					var t:TiltingPane05 = new TiltingPane05();
					_children[i] = t;
					var content:UIComponent = UIComponent(_itemRenderer.newInstance());
					IDataRenderer(content).data = _dataProvider.getItemAt(i);
					t.content = content;
					addChildAt(t,0);
				}
				for(i = numChildren-1;i>=_dataProvider.length;i--)
				{
					removeChildAt(numChildren-1);
				}
				_children.splice(_dataProvider.length,_children.length-_dataProvider.length);
			}
			
			_safeSelectedIndex = Math.max(0,Math.min(_selectedIndex,_children.length-1));
			
			invalidateDisplayList();
		}

		//---------------------------------------------------------------------------------------
		// measurement 
		//---------------------------------------------------------------------------------------
		override protected function measure():void
		{
			var mHeight:Number = 0;
			var mWidth:Number = 0;
			var t:TiltingPane05;
			for(var i:int = 0;i<_children.length;i++)
			{
				t = _children[i];
				mHeight = Math.max(t.measuredHeight,mHeight);
				mWidth = Math.max(t.measuredWidth,mWidth);
			}
			if(_children.length > 0)
			{			
				mWidth += (_children.length-1) * kPaneOverlap;
			}
			measuredHeight = mHeight;
			measuredWidth = mWidth;
		}
		
		//---------------------------------------------------------------------------------------
		// layout
		//---------------------------------------------------------------------------------------
		
		
		private function calcPositionForSelection(i:Number,sel:Number,c:ChildPosition):void
		{
			var t:TiltingPane05 = _children[i];
			var selected:TiltingPane05 = _children[sel];
			var adjacent:TiltingPane05;
			var a:Number = _angle;
			if(i == sel)
			{
				c.scale = 1;
	
				c.x = unscaledWidth/2 - t.getExplicitOrMeasuredWidth()/2;
				c.y = unscaledHeight/2 - t.getExplicitOrMeasuredHeight()/2;
				c.angle = 0;
			}
			else if (i < sel)
			{
				c.scale = (1-_popout);
				adjacent= _children[sel-1];
				var leftBase:Number = unscaledWidth/2 - selected.widthForAngle(0)/2 - (t.getExplicitOrMeasuredWidth()/2 +t.widthForAngle(a)*2/10) * c.scale;
				c.angle = _angle;
				c.x = leftBase - kPaneOverlap*(sel-1-i),
				c.y = unscaledHeight/2 - t.getExplicitOrMeasuredHeight()* (1-_popout)/2;
			}
			else
			{
				c.scale = (1-_popout);
				adjacent = _children[sel+1];
				var rightBase:Number  =  unscaledWidth/2 + selected.widthForAngle(0)/2 + (adjacent.widthForAngle(-_angle)*3/10 - adjacent.getExplicitOrMeasuredWidth()/2) * c.scale;
				c.angle = -_angle;
				c.x = rightBase + kPaneOverlap*(i-(sel+1));
				c.y = unscaledHeight/2 - t.getExplicitOrMeasuredHeight() * (1-_popout)/2;
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			if(_children.length == 0)
				return;

			var c:ChildPosition = new ChildPosition();
			var t:TiltingPane05;
			var m:Matrix;
			
			for(var i:int = 0;i<=_safeSelectedIndex;i++)
			{
				calcPositionForSelection(i,_safeSelectedIndex,c);				
				t = _children[i];
				t.setActualSize(t.getExplicitOrMeasuredWidth(),t.getExplicitOrMeasuredHeight());
				t.setActualAngle(c.angle);
				setChildIndex(t,i);
				m = t.transform.matrix;
				m.a = m.d = c.scale;
				t.transform.matrix = m;
				t.move(c.x,c.y);
			}

			for(i = Math.floor(_safeSelectedIndex)+1; i< _children.length;i++)
			{
				calcPositionForSelection(i,_safeSelectedIndex,c);				
				t = _children[i];
				t.setActualSize(t.getExplicitOrMeasuredWidth(),t.getExplicitOrMeasuredHeight());
				t.setActualAngle(c.angle);
				t.move(c.x,c.y);
				setChildIndex(t,0);
				m = t.transform.matrix;
				m.a = m.d = c.scale;
				t.transform.matrix = m;
			}
		
			setChildIndex(_children[Math.round(_safeSelectedIndex)],numChildren-1);
			
			
		}

		private function dataChangeHandler(event:CollectionEvent):void	
		{
			_itemsDirty = true;
			invalidateProperties();
		}
		
	    override protected function keyDownHandler(event:KeyboardEvent):void
	    {
	    	super.keyDownHandler(event);
			switch(event.keyCode)
			{
				case Keyboard.LEFT:
					selectedIndex = Math.max(0,selectedIndex-1);
					event.stopPropagation();
					break;
				case Keyboard.RIGHT:
					selectedIndex = Math.min(_dataProvider.length-1,selectedIndex+1);
					event.stopPropagation();
					break;					
			}
	    }
	}
}

class ChildPosition
{
	public var angle:Number;
	public var x:Number;
	public var y:Number;
	public var scale:Number;
}
