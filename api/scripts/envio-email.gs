/**
 * MembroPass — envio de e-mails pelo Gmail (Google Apps Script).
 *
 * A API online não pode usar SMTP, então ela chama este script por HTTPS
 * e ele envia o e-mail pela conta do Gmail onde foi publicado.
 * Passo a passo no README, seção "Publicar online".
 */

// Mesmo valor da variável EMAIL_APPS_SCRIPT_SEGREDO da API.
const SEGREDO = 'COLE-O-SEGREDO-AQUI';

/** Recebe o pedido da API e envia o e-mail. */
function doPost(e) {
  try {
    const pedido = JSON.parse(e.postData.contents);
    const semSegredo = SEGREDO.length < 32; // ainda com o texto de exemplo
    if (semSegredo || pedido.segredo !== SEGREDO) return responder({ erro: 'não autorizado' });
    enviar(pedido.para, pedido.assunto, pedido.texto, pedido.html);
    return responder({ ok: true });
  } catch (erro) {
    return responder({ erro: String(erro) });
  }
}

/** Rode esta função no editor para autorizar o Gmail e receber um teste. */
function testar() {
  const eu = Session.getActiveUser().getEmail();
  enviar(eu, 'Teste do MembroPass', 'O envio de e-mails está funcionando.', '<p>O envio de e-mails está funcionando.</p>');
  Logger.log('E-mail de teste enviado para ' + eu);
}

function enviar(para, assunto, texto, html) {
  GmailApp.sendEmail(para, assunto, texto || '', { htmlBody: html, name: 'MembroPass' });
}

function responder(objeto) {
  return ContentService.createTextOutput(JSON.stringify(objeto)).setMimeType(ContentService.MimeType.JSON);
}
