import React from 'react';

// TODO import PATH!
import tf from '../../textfilter';
const TextFilter = tf.component;

export default function MapControls(props) {
    return (
        <div>
            <TextFilter
                labelSingular='person'
                labelPlural='people'
                entries={props.userFilterEntries}
                expanded={props.userFilterExpanded}
                onAddEntry={props.onAddUserFilter}
                onRemoveEntry={props.onRemoveUserFilter}
                onToggleMenu={props.onToggleUserFilter}/>
        </div>
    );
}

MapControls.propTypes = {
    userFilterEntries: TextFilter.propTypes.entries,
    userFilterExpanded: TextFilter.propTypes.expanded,
    onAddUserFilter: TextFilter.propTypes.onAddEntry,
    onRemoveUserFilter: TextFilter.propTypes.onRemoveEntry,
    onToggleUserFilter: TextFilter.propTypes.onToggleMenu,
}
