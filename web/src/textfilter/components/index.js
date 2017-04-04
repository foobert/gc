import React from 'react';

// TODO ARGH PATH!
import LabelPlural from '../../components/labelPlural';

import TextFilterEntry from './entry';

export default class TextFilter extends React.Component {
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
                    { this.props.entries.map((x) => <TextFilterEntry key={x} label={x} onRemoveClick={(e) => this.handleRemove(e, x) }/>) }
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
