'use babel';

import EmpProjectViewView from './emp-project-view';
import { CompositeDisposable } from 'atom';

export default {

  empProjectViewView: null,
  modalPanel: null,
  subscriptions: null,

  activate(state) {
    this.empProjectViewView = new EmpProjectViewView(state.empProjectViewViewState);
    this.modalPanel = atom.workspace.addModalPanel({
      item: this.empProjectViewView.getElement(),
      visible: false
    });

    // Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    this.subscriptions = new CompositeDisposable();

    // Register command that toggles this view
    this.subscriptions.add(atom.commands.add('atom-workspace', {
      'emp-project-view:toggle': () => this.toggle()
    }));
  },

  deactivate() {
    this.modalPanel.destroy();
    this.subscriptions.dispose();
    this.empProjectViewView.destroy();
  },

  serialize() {
    return {
      empProjectViewViewState: this.empProjectViewView.serialize()
    };
  },

  toggle() {
    console.log('EmpProjectView was toggled!');
    return (
      this.modalPanel.isVisible() ?
      this.modalPanel.hide() :
      this.modalPanel.show()
    );
  }

};
