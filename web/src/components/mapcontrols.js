import React from 'react';
import classnames from 'classnames';

import LabelPlural from './labelPlural';

class TextFilter extends React.Component {
    constructor(props) {
        super(props);
        this.state = {value: ''};
    }

    handleClick(e) {
        e.preventDefault();
        if (this.props.onToggleMenu) {
            this.props.onToggleMenu();
        }
    }

    handleAdd(e) {
        e.preventDefault();
        const newEntry = e.target.elements.newEntry.value;
        this.setState({value: ''});
        if (this.props.onAddEntry) {
            this.props.onAddEntry(newEntry);
        }
    }

    handleRemove(e, entry) {
        e.preventDefault();
        console.log(e);
        if (this.props.onRemoveEntry) {
            this.props.onRemoveEntry(entry);
        }
    }

    handleChange(e) {
        this.setState({value: e.target.value});
    }

    render() {
        return (
            <div>
                <div onClick={(e) => this.handleClick(e)}>
                    Filtering <LabelPlural
                        count={this.props.entries.length}
                        singular={this.props.labelSingular}
                        plural={this.props.labelPlural}/>
                </div>
                <div style={{display: this.props.expanded ? 'block' : 'none'}}>
                    { this.props.entries.map((x) => <TextFilterEntry key={x} user={x} onRemoveClick={(e) => this.handleRemove(e, x) }/>) }
                    <div>
                        <form onSubmit={(e) => this.handleAdd(e)}>
                            <input name='newEntry' type='text' value={this.state.value} onChange={(e) => this.handleChange(e)}/>
                        </form>
                    </div>
                </div>
            </div>
        );
    }
}

TextFilter.propTypes = {
    entries: React.PropTypes.array.isRequired,
    labelSingular: React.PropTypes.string.isRequired,
    labelPlural: React.PropTypes.string.isRequired,
    choices: React.PropTypes.arrayOf(React.PropTypes.element),
    expanded: React.PropTypes.bool.isRequired,
    onToggleMenu: React.PropTypes.func,
    onAddEntry: React.PropTypes.func,
    onRemoveEntry: React.PropTypes.func,
};

function TextFilterEntry(props) {
    return (
        <div>{ props.user } <span onClick={props.onRemoveClick}>X</span></div>
    );
}

function TypeFilter(props) {
    const filtered = props.filteredTypes || [];
    const label = filtered.length === 1 ? 'Filtering one geocache type' : `Filtering ${filtered.length} geocache types`;
    return (
        <div>
            <div>{ label }</div>
            { filtered.map((x) => <TypeFilterEntry key={x} type={x}/>) }
        </div>
    );
}

function TypeFilterEntry(props) {
    return (
        <div>{ props.type }</div>
    );
}

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
            <TypeFilter/>
        </div>
    );
}
