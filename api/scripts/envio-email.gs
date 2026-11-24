// MembroPass — envio de e-mails pelo Gmail, via Google Apps Script.
//
// A API online (Render gratuito) não pode usar SMTP. Este script roda na
// conta do Gmail e envia as mensagens que a API pede por HTTPS.
//
// Como publicar (uma vez, logado na conta do Gmail que vai enviar):
// 1. Abra https://script.google.com e crie um "Novo projeto".
// 2. Apague o conteúdo e cole este arquivo inteiro.
// 3. Troque SEGREDO abaixo por um texto aleatório longo (o mesmo vai na
//    variável EMAIL_APPS_SCRIPT_SEGREDO da API).
// 4. Implantar > Nova implantação > tipo "App da Web":
//      Executar como: Eu      Quem pode acessar: Qualquer pessoa
//    Autorize o acesso ao Gmail quando pedir.
// 5. Copie a URL do app da Web (termina em /exec) para EMAIL_APPS_SCRIPT_URL.
//
// Limite do Gmail gratuito: cerca de 100 destinatários por dia.

const SEGREDO = 'TROQUE-POR-UM-TEXTO-ALEATORIO-LONGO';

function doPost(e) {
  let dados;
  try {
    dados = JSON.parse(e.postData.contents);
  } catch (erro) {
    return responder({ erro: 'JSON inválido' });
  }
  if (SEGREDO.indexOf('TROQUE') === 0 || dados.segredo !== SEGREDO) {
    return responder({ erro: 'não autorizado' });
  }
  if (!dados.para || !dados.assunto) {
    return responder({ erro: 'faltam destinatário ou assunto' });
  }
  GmailApp.sendEmail(dados.para, dados.assunto, dados.texto || '', {
    htmlBody: dados.html,
    name: 'MembroPass',
  });
  return responder({ ok: true });
}

function responder(objeto) {
  return ContentService.createTextOutput(JSON.stringify(objeto)).setMimeType(ContentService.MimeType.JSON);
}
