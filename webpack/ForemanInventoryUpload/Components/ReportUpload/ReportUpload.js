import React from 'react';
import PropTypes from 'prop-types';
import { noop } from 'patternfly-react';
import TabContainer from '../TabContainer';
import TabHeader from '../TabHeader';
import TabBody from '../TabBody';
import './reportUpload.scss';

const ReportUpload = ({
  exitCode,
  logs,
  completed,
  downloadReports,
  restartProcess,
  error,
  toggleFullScreen,
}) => (
  <TabContainer className="report-upload">
    <TabHeader
      exitCode={exitCode}
      onRestart={restartProcess}
      onDownload={downloadReports}
      toggleFullScreen={toggleFullScreen}
    />
    <TabBody
      exitCode={exitCode}
      logs={logs}
      completed={completed}
      error={error}
    />
  </TabContainer>
);

ReportUpload.propTypes = {
  exitCode: PropTypes.string,
  logs: PropTypes.oneOfType([
    PropTypes.arrayOf(PropTypes.string),
    PropTypes.string,
  ]),
  completed: PropTypes.number,
  restartProcess: PropTypes.func,
  downloadReports: PropTypes.func,
  error: PropTypes.string,
  toggleFullScreen: PropTypes.func,
};

ReportUpload.defaultProps = {
  exitCode: '',
  logs: null,
  completed: 0,
  restartProcess: noop,
  downloadReports: noop,
  error: null,
  toggleFullScreen: noop,
};

export default ReportUpload;
