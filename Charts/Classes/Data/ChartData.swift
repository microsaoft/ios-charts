//
//  ChartData.swift
//  Charts
//
//  Created by Daniel Cohen Gindi on 23/2/15.

//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/ios-charts
//

import Foundation
import UIKit

public class ChartData: NSObject
{
    internal var _yMax = Float(0.0)
    internal var _yMin = Float(0.0)
    internal var _leftAxisMax = Float(0.0)
    internal var _leftAxisMin = Float(0.0)
    internal var _rightAxisMax = Float(0.0)
    internal var _rightAxisMin = Float(0.0)
    private var _yValueSum = Float(0.0)
    private var _yValCount = Int(0)
    
    /// the average length (in characters) across all x-value strings
    private var _xValAverageLength = Float(0.0)
    
    internal var _xVals: [String]!
    internal var _dataSets: [ChartDataSet]!
    
    public override init()
    {
        super.init();
        
        _xVals = [String]();
        _dataSets = [ChartDataSet]();
    }
    
    public init(xVals: [String]?)
    {
        super.init();
        
        _xVals = xVals == nil ? [String]() : xVals;
        _dataSets = [ChartDataSet]();
        
        self.initialize(_dataSets);
    }
    
    public convenience init(xVals: [String]?, dataSet: ChartDataSet?)
    {
        self.init(xVals: xVals, dataSets: dataSet === nil ? nil : [dataSet!]);
    }
    
    public init(xVals: [String]?, dataSets: [ChartDataSet]?)
    {
        super.init()
        
        _xVals = xVals == nil ? [String]() : xVals;
        _dataSets = dataSets == nil ? [ChartDataSet]() : dataSets;
        
        self.initialize(_dataSets)
    }
    
    internal func initialize(dataSets: [ChartDataSet])
    {
        checkIsLegal(dataSets);
        
        calcMinMax();
        calcYValueSum();
        calcYValueCount();
        
        calcXValAverageLength()
    }
    
    // calculates the average length (in characters) across all x-value strings
    internal func calcXValAverageLength()
    {
        if (_xVals.count == 0)
        {
            _xValAverageLength = 1;
            return;
        }
        
        var sum = 1;
        
        for (var i = 0; i < _xVals.count; i++)
        {
            sum += _xVals[i].lengthOfBytesUsingEncoding(NSUTF16StringEncoding);
        }
        
        _xValAverageLength = Float(sum) / Float(_xVals.count);
    }
    
    // Checks if the combination of x-values array and DataSet array is legal or not.
    // :param: dataSets
    internal func checkIsLegal(dataSets: [ChartDataSet]!)
    {
        if (dataSets == nil)
        {
            return;
        }
        
        for (var i = 0; i < dataSets.count; i++)
        {
            if (dataSets[i].yVals.count > _xVals.count)
            {
                println("One or more of the DataSet Entry arrays are longer than the x-values array of this Data object.");
                return;
            }
        }
    }
    
    public func notifyDataChanged()
    {
        initialize(_dataSets);
    }
    
    /// calc minimum and maximum y value over all datasets
    internal func calcMinMax()
    {
        if (_dataSets == nil || _dataSets.count < 1)
        {
            _yMax = 0.0;
            _yMin = 0.0;
        }
        else
        {
            // calculate absolute min and max
            _yMin = _dataSets[0].yMin;
            _yMax = _dataSets[0].yMax;
            
            for (var i = 0; i < _dataSets.count; i++)
            {
                if (_dataSets[i].yMin < _yMin)
                {
                    _yMin = _dataSets[i].yMin;
                }
                
                if (_dataSets[i].yMax > _yMax)
                {
                    _yMax = _dataSets[i].yMax;
                }
            }
            
            // left axis
            var firstLeft = getFirstLeft();

            if (firstLeft !== nil)
            {
                _leftAxisMax = firstLeft!.yMax;
                _leftAxisMin = firstLeft!.yMin;

                for dataSet in _dataSets
                {
                    if (dataSet.axisDependency == .Left)
                    {
                        if (dataSet.yMin < _leftAxisMin)
                        {
                            _leftAxisMin = dataSet.yMin;
                        }

                        if (dataSet.yMax > _leftAxisMax)
                        {
                            _leftAxisMax = dataSet.yMax;
                        }
                    }
                }
            }

            // right axis
            var firstRight = getFirstRight();

            if (firstRight !== nil)
            {
                _rightAxisMax = firstRight!.yMax;
                _rightAxisMin = firstRight!.yMin;
                
                for dataSet in _dataSets
                {
                    if (dataSet.axisDependency == .Right)
                    {
                        if (dataSet.yMin < _rightAxisMin)
                        {
                            _rightAxisMin = dataSet.yMin;
                        }

                        if (dataSet.yMax > _rightAxisMax)
                        {
                            _rightAxisMax = dataSet.yMax;
                        }
                    }
                }
            }

            // in case there is only one axis, adjust the second axis
            handleEmptyAxis(firstLeft, firstRight: firstRight);
        }
    }
    
    /// calculates the sum of all y-values in all datasets
    internal func calcYValueSum()
    {
        _yValueSum = 0;
        
        if (_dataSets == nil)
        {
            return;
        }
        
        for (var i = 0; i < _dataSets.count; i++)
        {
            _yValueSum += fabsf(_dataSets[i].yValueSum);
        }
    }
    
    /// Calculates the total number of y-values across all ChartDataSets the ChartData represents.
    internal func calcYValueCount()
    {
        _yValCount = 0;
        
        if (_dataSets == nil)
        {
            return;
        }
        
        var count = 0;
        
        for (var i = 0; i < _dataSets.count; i++)
        {
            count += _dataSets[i].entryCount;
        }
        
        _yValCount = count;
    }
    
    /// returns the number of LineDataSets this object contains
    public var dataSetCount: Int
    {
        if (_dataSets == nil)
        {
            return 0;
        }
        return _dataSets.count;
    }
    
    /// returns the smallest y-value the data object contains.
    public var yMin: Float
    {
        return _yMin;
    }
    
    public func getYMin() -> Float
    {
        return _yMin;
    }
    
    public func getYMin(axis: ChartYAxis.AxisDependency) -> Float
    {
        if (axis == .Left)
        {
            return _leftAxisMin;
        }
        else
        {
            return _rightAxisMin;
        }
    }
    
    /// returns the greatest y-value the data object contains.
    public var yMax: Float
    {
        return _yMax;
    }
    
    public func getYMax() -> Float
    {
        return _yMax;
    }
    
    public func getYMax(axis: ChartYAxis.AxisDependency) -> Float
    {
        if (axis == .Left)
        {
            return _leftAxisMax;
        }
        else
        {
            return _rightAxisMax;
        }
    }
    
    /// returns the average length (in characters) across all values in the x-vals array
    public var xValAverageLength: Float
    {
        return _xValAverageLength;
    }
    
    /// returns the total y-value sum across all DataSet objects the this object represents.
    public var yValueSum: Float
    {
        return _yValueSum;
    }
    
    /// Returns the total number of y-values across all DataSet objects the this object represents.
    public var yValCount: Int
    {
        return _yValCount;
    }
    
    /// returns the x-values the chart represents
    public var xVals: [String]
    {
        return _xVals;
    }
    
    ///Adds a new x-value to the chart data.
    public func addXValue(xVal: String)
    {
        _xVals.append(xVal);
    }
    
    /// Removes the x-value at the specified index.
    public func removeXValue(index: Int)
    {
        _xVals.removeAtIndex(index);
    }
    
    /// Returns the array of ChartDataSets this object holds.
    public var dataSets: [ChartDataSet]
    {
        get
        {
            return _dataSets;
        }
        set
        {
            _dataSets = newValue;
        }
    }
    
    /// Retrieve the index of a ChartDataSet with a specific label from the ChartData. Search can be case sensitive or not.
    /// IMPORTANT: This method does calculations at runtime, do not over-use in performance critical situations.
    ///
    /// :param: dataSets the DataSet array to search
    /// :param: type
    /// :param: ignorecase if true, the search is not case-sensitive
    /// :returns:
    internal func getDataSetIndexByLabel(label: String, ignorecase: Bool) -> Int
    {
        if (ignorecase)
        {
            for (var i = 0; i < dataSets.count; i++)
            {
                if (label.caseInsensitiveCompare(dataSets[i].label) == NSComparisonResult.OrderedSame)
                {
                    return i;
                }
            }
        }
        else
        {
            for (var i = 0; i < dataSets.count; i++)
            {
                if (label == dataSets[i].label)
                {
                    return i;
                }
            }
        }
        
        return -1;
    }
    
    /// returns the total number of x-values this ChartData object represents (the size of the x-values array)
    public var xValCount: Int
    {
        return _xVals.count;
    }
    
    /// Returns the labels of all DataSets as a string array.
    internal func dataSetLabels() -> [String]
    {
        var types = [String]();
        
        for (var i = 0; i < _dataSets.count; i++)
        {
            types[i] = _dataSets[i].label;
        }
        
        return types;
    }
    
    /// Get the Entry for a corresponding highlight object
    ///
    /// :param: highlight
    /// :returns: the entry that is highlighted
    public func getEntryForHighlight(highlight: ChartHighlight) -> ChartDataEntry
    {
        return _dataSets[highlight.dataSetIndex].entryForXIndex(highlight.xIndex);
    }
    
    /// Returns the DataSet object with the given label. 
    /// sensitive or not. 
    /// IMPORTANT: This method does calculations at runtime. Use with care in performance critical situations.
    ///
    /// :param: label
    /// :param: ignorecase
    public func getDataSetByLabel(label: String, ignorecase: Bool) -> ChartDataSet?
    {
        var index = getDataSetIndexByLabel(label, ignorecase: ignorecase);
        
        if (index < 0 || index >= _dataSets.count)
        {
            return nil;
        }
        else
        {
            return _dataSets[index];
        }
    }
    
    public func getDataSetByIndex(index: Int) -> ChartDataSet!
    {
        if (_dataSets == nil || index < 0 || index >= _dataSets.count)
        {
            return nil;
        }
        
        return _dataSets[index];
    }
    
    public func addDataSet(d: ChartDataSet!)
    {
        if (_dataSets == nil)
        {
            return;
        }
        
        _yValCount += d.entryCount;
        _yValueSum += d.yValueSum;
        
        if (_dataSets.count == 0)
        {
            _yMax = d.yMax;
            _yMin = d.yMin;
            
            if (d.axisDependency == .Left)
            {
                _leftAxisMax = d.yMax;
                _leftAxisMin = d.yMin;
            }
            else
            {
                _rightAxisMax = d.yMax;
                _rightAxisMin = d.yMin;
            }
        }
        else
        {
            if (_yMax < d.yMax)
            {
                _yMax = d.yMax;
            }
            if (_yMin > d.yMin)
            {
                _yMin = d.yMin;
            }
            
            if (d.axisDependency == .Left)
            {
                if (_leftAxisMax < d.yMax)
                {
                    _leftAxisMax = d.yMax;
                }
                if (_leftAxisMin > d.yMin)
                {
                    _leftAxisMin = d.yMin;
                }
            }
            else
            {
                if (_rightAxisMax < d.yMax)
                {
                    _rightAxisMax = d.yMax;
                }
                if (_rightAxisMin > d.yMin)
                {
                    _rightAxisMin = d.yMin;
                }
            }
        }
        
        _dataSets.append(d);
        
        handleEmptyAxis(getFirstLeft(), firstRight: getFirstRight());
    }
    
    public func handleEmptyAxis(firstLeft: ChartDataSet?, firstRight: ChartDataSet?)
    {
        // in case there is only one axis, adjust the second axis
        if (firstLeft === nil)
        {
            _leftAxisMax = _rightAxisMax;
            _leftAxisMin = _rightAxisMin;
        }
        else if (firstRight === nil)
        {
            _rightAxisMax = _leftAxisMax;
            _rightAxisMin = _leftAxisMin;
        }
    }
    
    /// Removes the given DataSet from this data object.
    /// Also recalculates all minimum and maximum values.
    ///
    /// :returns: true if a DataSet was removed, false if no DataSet could be removed.
    public func removeDataSet(dataSet: ChartDataSet!) -> Bool
    {
        if (_dataSets == nil || dataSet === nil)
        {
            return false;
        }
        
        var removed = false;
        for (var i = 0; i < _dataSets.count; i++)
        {
            if (_dataSets[i] === dataSet)
            {
                return removeDataSetByIndex(i);
            }
        }
        
        return false;
    }
    
    /// Removes the DataSet at the given index in the DataSet array from the data object. 
    /// Also recalculates all minimum and maximum values. 
    ///
    /// :returns: true if a DataSet was removed, false if no DataSet could be removed.
    public func removeDataSetByIndex(index: Int) -> Bool
    {
        if (_dataSets == nil || index >= _dataSets.count || index < 0)
        {
            return false;
        }
        
        var d = _dataSets.removeAtIndex(index);
        _yValCount -= d.entryCount;
        _yValueSum -= d.yValueSum;
        
        calcMinMax();
        
        return true;
    }
    
    /// Adds an Entry to the DataSet at the specified index. Entries are added to the end of the list.
    public func addEntry(e: ChartDataEntry, dataSetIndex: Int)
    {
        if (_dataSets != nil && _dataSets.count > dataSetIndex && dataSetIndex >= 0)
        {
            var val = e.value;
            
            _yValCount += 1;
            _yValueSum += val;
            
            if (_yMax < val)
            {
                _yMax = val;
            }
            if (_yMin > val)
            {
                _yMin = val;
            }
            
            var set = _dataSets[dataSetIndex];
            if (set.axisDependency == .Left)
            {
                if (_leftAxisMax < e.value)
                {
                    _leftAxisMax = e.value;
                }
                if (_leftAxisMin > e.value)
                {
                    _leftAxisMin = e.value;
                }
            }
            else
            {
                if (_rightAxisMax < e.value)
                {
                    _rightAxisMax = e.value;
                }
                if (_rightAxisMin > e.value)
                {
                    _rightAxisMin = e.value;
                }
            }
            
            handleEmptyAxis(getFirstLeft(), firstRight: getFirstRight());
            
            set.addEntry(e);
        }
        else
        {
            println("ChartData.addEntry() - dataSetIndex our of range.");
        }
    }
    
    /// Removes the given Entry object from the DataSet at the specified index.
    public func removeEntry(entry: ChartDataEntry!, dataSetIndex: Int) -> Bool
    {
        // entry null, outofbounds
        if (entry === nil || dataSetIndex >= _dataSets.count)
        {
            return false;
        }
        
        // remove the entry from the dataset
        var removed = _dataSets[dataSetIndex].removeEntry(xIndex: entry.xIndex);
        
        if (removed)
        {
            var val = entry.value;
            
            _yValCount -= 1;
            _yValueSum -= val;
            
            calcMinMax();
        }
        
        return removed;
    }
    
    /// Removes the Entry object at the given xIndex from the ChartDataSet at the
    /// specified index. Returns true if an entry was removed, false if no Entry
    /// was found that meets the specified requirements.
    public func removeEntryByXIndex(xIndex: Int, dataSetIndex: Int) -> Bool
    {
        if (dataSetIndex >= _dataSets.count)
        {
            return false;
        }
        
        var entry = _dataSets[dataSetIndex].entryForXIndex(xIndex);
        
        return removeEntry(entry, dataSetIndex: dataSetIndex);
    }
    
    /// Returns the DataSet that contains the provided Entry, or null, if no DataSet contains this entry.
    public func getDataSetForEntry(e: ChartDataEntry!) -> ChartDataSet?
    {
        if (e == nil)
        {
            return nil;
        }
        
        for (var i = 0; i < _dataSets.count; i++)
        {
            var set = _dataSets[i];
            
            for (var j = 0; j < set.entryCount; j++)
            {
                if (e === set.entryForXIndex(e.xIndex))
                {
                    return set;
                }
            }
        }
        
        return nil;
    }
    
    /// Returns the index of the provided DataSet inside the DataSets array of
    /// this data object. Returns -1 if the DataSet was not found.
    public func indexOfDataSet(dataSet: ChartDataSet) -> Int
    {
        for (var i = 0; i < _dataSets.count; i++)
        {
            if (_dataSets[i] === dataSet)
            {
                return i;
            }
        }
        
        return -1;
    }
    
    public func getFirstLeft() -> ChartDataSet?
    {
        for dataSet in _dataSets
        {
            if (dataSet.axisDependency == .Left)
            {
                return dataSet;
            }
        }
        
        return nil;
    }
    
    public func getFirstRight() -> ChartDataSet?
    {
        for dataSet in _dataSets
        {
            if (dataSet.axisDependency == .Right)
            {
                return dataSet;
            }
        }
        
        return nil;
    }
    
    /// Returns all colors used across all DataSet objects this object represents.
    public func getColors() -> [UIColor]?
    {
        if (_dataSets == nil)
        {
            return nil;
        }
        
        var clrcnt = 0;
        
        for (var i = 0; i < _dataSets.count; i++)
        {
            clrcnt += _dataSets[i].colors.count;
        }
        
        var colors = [UIColor]();
        
        for (var i = 0; i < _dataSets.count; i++)
        {
            var clrs = _dataSets[i].colors;
            
            for clr in clrs
            {
                colors.append(clr);
            }
        }
        
        return colors;
    }
    
    /// Generates an x-values array filled with numbers in range specified by the parameters. Can be used for convenience.
    public func generateXVals(from: Int, to: Int) -> [String]
    {
        var xvals = [String]();
        
        for (var i = from; i < to; i++)
        {
            xvals.append(String(i));
        }
        
        return xvals;
    }
    
    /// Sets a custom ValueFormatter for all DataSets this data object contains.
    public func setValueFormatter(formatter: NSNumberFormatter!)
    {
        for set in dataSets
        {
            set.valueFormatter = formatter;
        }
    }
    
    /// Sets the color of the value-text (color in which the value-labels are drawn) for all DataSets this data object contains.
    public func setValueTextColor(color: UIColor!)
    {
        for set in dataSets
        {
            set.valueTextColor = color ?? set.valueTextColor;
        }
    }
    
    /// Sets the font for all value-labels for all DataSets this data object contains.
    public func setValueFont(font: UIFont!)
    {
        for set in dataSets
        {
            set.valueFont = font ?? set.valueFont;
        }
    }
    
    /// Enables / disables drawing values (value-text) for all DataSets this data object contains.
    public func setDrawValues(enabled: Bool)
    {
        for set in dataSets
        {
            set.drawValuesEnabled = enabled;
        }
    }
    
    /// Clears this data object from all DataSets and removes all Entries.
    public func clearValues()
    {
        dataSets.removeAll(keepCapacity: false);
        notifyDataChanged();
    }
    
    /// Checks if this data object contains the specified Entry. Returns true if so, false if not.
    public func contains(#entry: ChartDataEntry) -> Bool
    {
        for set in dataSets
        {
            if (set.contains(entry))
            {
                return true;
            }
        }
        
        return false;
    }
    
    /// Checks if this data object contains the specified DataSet. Returns true if so, false if not.
    public func contains(#dataSet: ChartDataSet) -> Bool
    {
        for set in dataSets
        {
            if (set.isEqual(dataSet))
            {
                return true;
            }
        }
        
        return false;
    }
}
