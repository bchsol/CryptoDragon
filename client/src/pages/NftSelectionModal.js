import React from "react";
import { Modal, Row, Col, Card, Form, Button } from "react-bootstrap";

const NftSelectionModal = ({
  show,
  onHide,
  nftIds,
  selectedNft,
  onSelectNft,
  title,
  onConfirm,
}) => {
  return (
    <Modal show={show} size="lg" onHide={onHide} centered>
      <Modal.Header closeButton>
        <Modal.Title>{title}</Modal.Title>
      </Modal.Header>
      <Modal.Body>
        <Row xs={1} sm={2} md={3} lg={4} xl={4} xxl={5} gap={4}>
          {nftIds?.map((nftId) => (
            <Col key={nftId.id} className="modal-col">
              <Card border="dark" className="text-center card-custom">
                <Card.Img src={nftId.imageUrl} />
                <Card.Title>{nftId.name}</Card.Title>
                <Card.Footer>
                  <Form.Check
                    type="checkbox"
                    name="Nft"
                    checked={selectedNft && selectedNft.id === nftId.id}
                    onChange={() => onSelectNft(nftId)}
                  />
                </Card.Footer>
              </Card>
            </Col>
          ))}
        </Row>
      </Modal.Body>
      <Modal.Footer>
        <Button variant="outline-dark" onClick={onConfirm}>
          Confirm
        </Button>
      </Modal.Footer>
    </Modal>
  );
};

export default NftSelectionModal;
