import React from "react";
import { Modal, Button } from "react-bootstrap";

const displayTime = (seconds) => {
  const days = Math.floor(seconds / (24 * 3600));
  const hours = Math.floor((seconds % (24 * 3600)) / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const remainingSeconds = seconds % 60;

  return `${days} days ${hours} hours ${minutes} minutes ${remainingSeconds} seconds`;
};

const CollectionInfoModal = ({
  show,
  onHide,
  info,
  stage,
  timeRemaining,
  feeding,
  evolve,
}) => {
  const handleFeeding = () => feeding();
  const handleEvolve = () => evolve();
 
  return (
    <Modal show={show} onHide={onHide} size="lg" centered>
      <Modal.Header closeButton>
        <Modal.Title>Token Info</Modal.Title>
      </Modal.Header>
      <Modal.Body>
        <ul>
          <li>Type : {info.tokenType}</li>
          <li>Gender : {stage === "egg" ? "secret" : Number(info.gender) % 2 == 0 ? "Female" : "Male"}</li>
          <li>Father TokenId : {Number(info.wifeId)}</li>
          <li>Mother TokenId : {Number(info.husbandId)}</li>
          <li>Generation : {Number(info.generation)} Gen</li>
        </ul>

        <ul>
          <li>CurrentStage : {stage}</li>
          <li>timeRemaining : {displayTime(timeRemaining)}</li>
        </ul>
        <Button style={{ margin: "0 20px" }} onClick={handleFeeding}>
          Feed
        </Button>

        <Button onClick={handleEvolve}>Evolve</Button>
      </Modal.Body>
      <Modal.Footer></Modal.Footer>
    </Modal>
  );
};

export default CollectionInfoModal;
